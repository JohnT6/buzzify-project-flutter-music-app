part of 'data_bloc.dart';

@immutable
abstract class DataEvent {}

class FetchDataRequested extends DataEvent {
  final String? userId; // <-- Cần userId để lấy danh sách yêu thích
  FetchDataRequested({this.userId});
}

// Event mới để toggle like
class ToggleLikeSong extends DataEvent {
  final String songId;
  ToggleLikeSong(this.songId);
}