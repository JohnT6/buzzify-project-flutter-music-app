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
  final List<Map<String, dynamic>> artists;
  final List<Map<String, dynamic>> playlists;
  final Set<String> likedSongIds;

  const DataLoaded({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
    this.likedSongIds = const {},
  });

  // Thêm hàm copyWith để update state dễ dàng
  DataLoaded copyWith({
    List<Map<String, dynamic>>? songs,
    List<Map<String, dynamic>>? albums,
    List<Map<String, dynamic>>? artists,
    List<Map<String, dynamic>>? playlists,
    Set<String>? likedSongIds,
  }) {
    return DataLoaded(
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      playlists: playlists ?? this.playlists,
      likedSongIds: likedSongIds ?? this.likedSongIds,
    );
  }

  @override
  List<Object> get props => [songs, albums, artists, playlists, likedSongIds];
}

// Trạng thái khi có lỗi xảy ra
class DataError extends DataState {
  final String message;
  const DataError(this.message);

  @override
  List<Object> get props => [message];
}
