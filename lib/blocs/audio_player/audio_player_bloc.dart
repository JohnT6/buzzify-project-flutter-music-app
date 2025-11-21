// lib/blocs/audio_player/audio_player_bloc.dart

import 'dart:async';
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

part 'audio_player_event.dart';
part 'audio_player_state.dart';

class AudioPlayerBloc extends HydratedBloc<AudioPlayerEvent, AudioPlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  AudioPlayer get player => _audioPlayer;

  AudioPlayerBloc() : super(const AudioPlayerState()) {
    on<StartPlaying>(_onStartPlaying);
    on<PlayRequested>(_onPlayRequested); // Tách ra hàm riêng để xử lý logic load lại nếu cần
    on<PauseRequested>((event, emit) => _audioPlayer.pause());
    on<NextSongRequested>((event, emit) => _audioPlayer.seekToNext());
    on<PreviousSongRequested>((event, emit) => _audioPlayer.seekToPrevious());
    on<SeekToPosition>((event, emit) => _audioPlayer.seek(event.position));
    on<ToggleShuffleRequested>(_onToggleShuffle);
    on<ToggleRepeatRequested>(_onToggleRepeat);
    on<FetchLyricsRequested>(_onFetchLyrics);
    on<LogoutReset>(_onLogoutReset);
    
    _listenToPlayerChanges();
  }

  // --- SỬA LỖI: Cập nhật UI ngay lập tức (Optimistic Update) ---
  Future<void> _onStartPlaying(StartPlaying event, Emitter<AudioPlayerState> emit) async {
    try {
      final bool isNewPlaylist = state.currentPlaylist != event.playlist;
      // Kiểm tra kỹ: Nếu player chưa có nguồn nhạc hoặc playlist trống
      final bool isPlayerEmpty = _audioPlayer.audioSource == null || state.currentPlaylist.isEmpty;

      // 1. Nạp nhạc vào Player (Nếu cần)
      if (isNewPlaylist || isPlayerEmpty) {
        final audioSources = event.playlist.map((song) {
          final url = song['url']; 
          if (url == null) throw Exception('URL null');
          return AudioSource.uri(Uri.parse(url), tag: song);
        }).toList();

        await _audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: audioSources),
          initialIndex: event.index,
          preload: true
        );
      } else {
        // Nếu playlist cũ -> Chỉ cần nhảy tới bài
        await _audioPlayer.seek(Duration.zero, index: event.index);
      }
      
      // 2. QUAN TRỌNG: Cập nhật giao diện NGAY LẬP TỨC
      // (Trước khi gọi play() để tránh bị kẹt UI nếu play() gặp lỗi)
      emit(state.copyWith(
        isPlaying: true, // Hiển thị nút Pause ngay
        currentPlaylist: event.playlist,
        currentIndex: event.index,
        playlistTitle: event.playlistTitle ?? 'Danh sách bài hát',
        contextId: event.contextId,
        lyrics: [],
        lyricsStatus: LyricsStatus.initial, 
        currentLyricIndex: -1,
      ));

      // 3. Bây giờ mới gọi lệnh phát nhạc
      // (Nếu máy ảo lỗi codec ở đây, UI vẫn đã hiển thị đúng bài hát)
      await _audioPlayer.play();
      
    } catch (e) {
      print('Lỗi phát nhạc: $e');
      // Nếu lỗi thực sự xảy ra và nhạc không chạy, ta mới trả trạng thái về Pause
      emit(state.copyWith(isPlaying: false));
    }
  }

  // Xử lý riêng cho nút Play trên Miniplayer (đề phòng trường hợp mở lại app nhưng chưa load source)
  Future<void> _onPlayRequested(PlayRequested event, Emitter<AudioPlayerState> emit) async {
    if (_audioPlayer.audioSource == null && state.currentPlaylist.isNotEmpty) {
        // Nếu player rỗng mà state vẫn có bài (do HydratedBloc), hãy nạp lại source
        final audioSources = state.currentPlaylist.map((song) => AudioSource.uri(Uri.parse(song['url']))).toList();
        await _audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: audioSources),
          initialIndex: state.currentIndex ?? 0,
        );
    }
    _audioPlayer.play();
  }

  void _onToggleShuffle(ToggleShuffleRequested event, Emitter<AudioPlayerState> emit) {
    final isEnabled = !_audioPlayer.shuffleModeEnabled;
    _audioPlayer.setShuffleModeEnabled(isEnabled);
  }

  void _onToggleRepeat(ToggleRepeatRequested event, Emitter<AudioPlayerState> emit) {
    LoopMode nextMode;
    if (state.loopMode == LoopMode.off) nextMode = LoopMode.all;
    else if (state.loopMode == LoopMode.all) nextMode = LoopMode.one;
    else nextMode = LoopMode.off;
    _audioPlayer.setLoopMode(nextMode);
  }

  Future<void> _onFetchLyrics(FetchLyricsRequested event, Emitter<AudioPlayerState> emit) async {
    if (state.currentSong == null) return;
    emit(state.copyWith(lyricsStatus: LyricsStatus.loading));
    try {
      final song = state.currentSong!;
      final artistName = Uri.encodeComponent(song['artists']?['name'] ?? '');
      final trackName = Uri.encodeComponent(song['title'] ?? '');
      final albumName = Uri.encodeComponent(song['album_name'] ?? '');
      
      final url = Uri.parse('https://lrclib.net/api/get?artist_name=$artistName&track_name=$trackName&album_name=$albumName');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['syncedLyrics'] != null && data['syncedLyrics'].isNotEmpty) {
          final parsedLyrics = _parseLrc(data['syncedLyrics']);
          emit(state.copyWith(lyricsStatus: LyricsStatus.loaded, lyrics: parsedLyrics));
        } else {
          emit(state.copyWith(lyricsStatus: LyricsStatus.failure));
        }
      } else {
        emit(state.copyWith(lyricsStatus: LyricsStatus.failure));
      }
    } catch (e) {
      emit(state.copyWith(lyricsStatus: LyricsStatus.failure));
    }
  }

  Future<void> _onLogoutReset(LogoutReset event, Emitter<AudioPlayerState> emit) async {
    await _audioPlayer.stop();
    // Clear hoàn toàn state
    emit(const AudioPlayerState());
    await clear();
  }

  // --- FIX 2: TRÁNH NHẢY INDEX KHI RESET ---
  void _listenToPlayerChanges() {
    _audioPlayer.playerStateStream.listen((playerState) {
      if (!isClosed) emit(state.copyWith(isPlaying: playerState.playing));
    });

    _audioPlayer.positionStream.listen((position) {
      if (isClosed) return;
      int newLyricIndex = -1;
      if (state.lyrics.isNotEmpty) {
        final adjustedPosition = position - const Duration(milliseconds: 500);
        newLyricIndex = state.lyrics.lastIndexWhere((line) => adjustedPosition >= line.timestamp);
      }
      emit(state.copyWith(position: position, currentLyricIndex: newLyricIndex));
    });
    
    _audioPlayer.durationStream.listen((duration) {
      if (!isClosed && duration != null) emit(state.copyWith(totalDuration: duration));
    });

    _audioPlayer.currentIndexStream.listen((index) {
      // QUAN TRỌNG: Chỉ cập nhật index khi nó hợp lệ VÀ Player đã có source
      // Điều này ngăn chặn việc index bị reset về 0 hoặc null khi mới mở app
      if (!isClosed && index != null && _audioPlayer.audioSource != null) {
        emit(state.copyWith(currentIndex: index, lyrics: [], lyricsStatus: LyricsStatus.initial, currentLyricIndex: -1));
        add(FetchLyricsRequested());
      }
    });

    _audioPlayer.shuffleModeEnabledStream.listen((isEnabled) {
      if (!isClosed) emit(state.copyWith(isShuffling: isEnabled));
    });

    _audioPlayer.loopModeStream.listen((loopMode) {
      if (!isClosed) emit(state.copyWith(loopMode: loopMode));
    });
  }
  
  List<LyricLine> _parseLrc(String lrcString) {
    final List<LyricLine> lines = [];
    final regExp = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    for (final line in lrcString.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();
        if (text.isNotEmpty) lines.add(LyricLine(Duration(minutes: min, seconds: sec, milliseconds: ms), text));
      }
    }
    return lines;
  }

  @override
  Future<void> close() {
    _audioPlayer.dispose();
    return super.close();
  }

  @override
  AudioPlayerState? fromJson(Map<String, dynamic> json) {
    try {
      final storedState = AudioPlayerState.fromJson(json);
      // LƯU Ý: Không tự động setAudioSource ở đây để tránh xung đột khi khởi động.
      // Việc load source sẽ được thực hiện ở _onStartPlaying hoặc _onPlayRequested.
      return storedState;
    } catch (_) { return null; }
  }

  @override
  Map<String, dynamic>? toJson(AudioPlayerState state) => state.toJson();
}