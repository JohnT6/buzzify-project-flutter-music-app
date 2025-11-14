part of 'data_bloc.dart';

@immutable
abstract class DataState extends Equatable {
  const DataState();
  @override
  List<Object> get props => [];
}

// Trạng thái ban đầu hoặc đang tải dữ liệu
class DataLoading extends DataState {}

// Trạng thái đã tải dữ liệu thành công
class DataLoaded extends DataState {
  final List<Map<String, dynamic>> songs;
  final List<Map<String, dynamic>> albums;
  final List<Map<String, dynamic>> artists; // <-- THÊM MỚI
  final List<Map<String, dynamic>> playlists; // <-- THÊM MỚI

  const DataLoaded({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [], // <-- THÊM MỚI
    this.playlists = const [],
  });

  @override
  List<Object> get props => [songs, albums, artists, playlists];
}

// Trạng thái khi có lỗi xảy ra
class DataError extends DataState {
  final String message;
  const DataError(this.message);

  @override
  List<Object> get props => [message];
}
