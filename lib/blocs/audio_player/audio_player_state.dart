part of 'audio_player_bloc.dart';

// Enum để quản lý trạng thái của việc tải lyrics
enum LyricsStatus { initial, loading, loaded, failure }

// Lớp chứa một dòng lyric
class LyricLine extends Equatable {
  final Duration timestamp;
  final String text;

  const LyricLine(this.timestamp, this.text);

  @override
  List<Object?> get props => [timestamp, text];
}

class AudioPlayerState extends Equatable {
  // Trạng thái trình phát
  final bool isPlaying;
  final List<Map<String, dynamic>> currentPlaylist;
  final int? currentIndex;
  final Duration position;
  final Duration totalDuration;
  final LoopMode loopMode;
  final bool isShuffling;
  
  // Trạng thái của Lyrics
  final List<LyricLine> lyrics;
  final LyricsStatus lyricsStatus;
  final int currentLyricIndex;

  const AudioPlayerState({
    this.isPlaying = false,
    this.currentPlaylist = const [],
    this.currentIndex,
    this.position = Duration.zero,
    this.totalDuration = Duration.zero,
    this.loopMode = LoopMode.off,
    this.isShuffling = false,
    this.lyrics = const [],
    this.lyricsStatus = LyricsStatus.initial,
    this.currentLyricIndex = -1,
  });
  
  Map<String, dynamic>? get currentSong {
    if (currentIndex != null && currentIndex! >= 0 && currentIndex! < currentPlaylist.length) {
      return currentPlaylist[currentIndex!];
    }
    return null;
  }
  
  AudioPlayerState copyWith({
    bool? isPlaying,
    List<Map<String, dynamic>>? currentPlaylist,
    int? currentIndex,
    Duration? position,
    Duration? totalDuration,
    LoopMode? loopMode,
    bool? isShuffling,
    List<LyricLine>? lyrics,
    LyricsStatus? lyricsStatus,
    int? currentLyricIndex,
  }) {
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      totalDuration: totalDuration ?? this.totalDuration,
      loopMode: loopMode ?? this.loopMode,
      isShuffling: isShuffling ?? this.isShuffling,
      lyrics: lyrics ?? this.lyrics,
      lyricsStatus: lyricsStatus ?? this.lyricsStatus,
      currentLyricIndex: currentLyricIndex ?? this.currentLyricIndex,
    );
  }

  @override
  List<Object?> get props => [
        isPlaying,
        currentPlaylist,
        currentIndex,
        position,
        totalDuration,
        loopMode,
        isShuffling,
        lyrics,
        lyricsStatus,
        currentLyricIndex,
      ];
  
  // === Dành cho HydratedBloc ===
  Map<String, dynamic> toJson() {
    return {
      'currentPlaylist': currentPlaylist,
      'currentIndex': currentIndex,
    };
  }

  factory AudioPlayerState.fromJson(Map<String, dynamic> json) {
    final playlist = (json['currentPlaylist'] as List<dynamic>?)
        ?.map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    return AudioPlayerState(
      currentPlaylist: playlist ?? [],
      currentIndex: json['currentIndex'] as int?,
    );
  }
}