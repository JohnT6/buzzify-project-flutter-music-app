import 'dart:async';
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

part 'audio_player_event.dart';
part 'audio_player_state.dart';

class AudioPlayerBloc extends HydratedBloc<AudioPlayerEvent, AudioPlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Public getter để UI có thể truy cập
  AudioPlayer get player => _audioPlayer;

  AudioPlayerBloc() : super(const AudioPlayerState()) {
    on<StartPlaying>(_onStartPlaying);
    on<PlayRequested>((event, emit) => _audioPlayer.play());
    on<PauseRequested>((event, emit) => _audioPlayer.pause());
    on<NextSongRequested>((event, emit) => _audioPlayer.seekToNext());
    on<PreviousSongRequested>((event, emit) => _audioPlayer.seekToPrevious());
    on<SeekToPosition>((event, emit) => _audioPlayer.seek(event.position));
    on<ToggleShuffleRequested>(_onToggleShuffle);
    on<ToggleRepeatRequested>(_onToggleRepeat);
    on<FetchLyricsRequested>(_onFetchLyrics);
    
    _listenToPlayerChanges();
  }

  Future<void> _onStartPlaying(StartPlaying event, Emitter<AudioPlayerState> emit) async {
    final isNewPlaylist = state.currentPlaylist != event.playlist;
    if (isNewPlaylist) {
      final audioSources = event.playlist.map((song) {
        final url = Supabase.instance.client.storage.from('Buzzify').getPublicUrl(song['audio_url']);
        return AudioSource.uri(Uri.parse(url));
      }).toList();
      await _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: audioSources));
    }
    
    await _audioPlayer.seek(Duration.zero, index: event.index);
    await _audioPlayer.play();
    
    emit(state.copyWith(
      currentPlaylist: event.playlist,
      currentIndex: event.index,
      // Reset lyrics khi chuyển bài
      lyrics: [],
      lyricsStatus: LyricsStatus.initial, 
      currentLyricIndex: -1,
    ));
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
      final url = Uri.parse('https://lrclib.net/api/get?artist_name=$artistName&track_name=$trackName');
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
      if (!isClosed && index != null) {
        emit(state.copyWith(currentIndex: index, lyrics: [], lyricsStatus: LyricsStatus.initial, currentLyricIndex: -1));
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
      if (storedState.currentPlaylist.isNotEmpty) {
        final audioSources = storedState.currentPlaylist.map((song) {
          final url = Supabase.instance.client.storage.from('Buzzify').getPublicUrl(song['audio_url']);
          return AudioSource.uri(Uri.parse(url));
        }).toList();
        _audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: audioSources), 
          initialIndex: storedState.currentIndex, 
          preload: false
        );
      }
      return storedState;
    } catch (_) { return null; }
  }

  @override
  Map<String, dynamic>? toJson(AudioPlayerState state) => state.toJson();
}