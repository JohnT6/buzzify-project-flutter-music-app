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
  
  const DataLoaded({this.songs = const [], this.albums = const []});

  @override
  List<Object> get props => [songs, albums];
}

// Trạng thái khi có lỗi xảy ra
class DataError extends DataState {
  final String message;
  const DataError(this.message);

  @override
  List<Object> get props => [message];
}