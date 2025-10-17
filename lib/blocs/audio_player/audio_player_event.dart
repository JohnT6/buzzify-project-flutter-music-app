part of 'audio_player_bloc.dart';

@immutable
abstract class AudioPlayerEvent extends Equatable {
  const AudioPlayerEvent();
  @override
  List<Object> get props => [];
}

// Bắt đầu phát một playlist từ một vị trí cụ thể
class StartPlaying extends AudioPlayerEvent {
  final List<Map<String, dynamic>> playlist;
  final int index;
  const StartPlaying({required this.playlist, required this.index});

  @override
  List<Object> get props => [playlist, index];
}

// Các event điều khiển trình phát
class PlayRequested extends AudioPlayerEvent {}
class PauseRequested extends AudioPlayerEvent {}
class NextSongRequested extends AudioPlayerEvent {}
class PreviousSongRequested extends AudioPlayerEvent {}

class SeekToPosition extends AudioPlayerEvent {
  final Duration position;
  const SeekToPosition(this.position);

  @override
  List<Object> get props => [position];
}

// Event cho Shuffle và Repeat
class ToggleShuffleRequested extends AudioPlayerEvent {}
class ToggleRepeatRequested extends AudioPlayerEvent {}

// Event cho Lyrics
class FetchLyricsRequested extends AudioPlayerEvent {}