part of 'data_bloc.dart';

@immutable
abstract class DataEvent {}

// Event để yêu cầu BLoC bắt đầu tải dữ liệu từ Supabase
class FetchDataRequested extends DataEvent {}