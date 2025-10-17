import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'data_event.dart';
part 'data_state.dart';

class DataBloc extends Bloc<DataEvent, DataState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  DataBloc() : super(DataLoading()) {
    on<FetchDataRequested>(_onFetchDataRequested);
  }

  Future<void> _onFetchDataRequested(
      FetchDataRequested event, Emitter<DataState> emit) async {
    emit(DataLoading());
    try {
      // Gọi API song song để lấy dữ liệu songs và albums
      final responses = await Future.wait([
        _supabase.from('songs').select('*, artists(name)'),
        _supabase.from('albums').select('*, artists(name), songs(*, artists(name))'),
      ]);

      final songsData = List<Map<String, dynamic>>.from(responses[0] as List);
      final albumsData = List<Map<String, dynamic>>.from(responses[1] as List);

      // Phát ra trạng thái thành công kèm theo dữ liệu
      emit(DataLoaded(songs: songsData, albums: albumsData));
    } catch (e) {
      // Phát ra trạng thái lỗi nếu có sự cố
      emit(DataError(e.toString()));
    }
  }
}