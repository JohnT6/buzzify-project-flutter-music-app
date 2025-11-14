// lib/blocs/data/data_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
// Bỏ import Supabase
// import 'package:supabase_flutter/supabase_flutter.dart';

// Import các service
import 'package:buzzify/services/api_song_service.dart';
import 'package:buzzify/services/api_album_service.dart';
import 'package:buzzify/services/api_artist_service.dart'; // <-- THÊM MỚI
import 'package:buzzify/services/api_playlist_service.dart'; // <-- THÊM MỚI

part 'data_event.dart';
part 'data_state.dart';

class DataBloc extends Bloc<DataEvent, DataState> {
  // Không dùng Supabase ở đây nữa
  // final SupabaseClient _supabase = Supabase.instance.client;

  // Dùng service
  final ApiSongService _songService;
  final ApiAlbumService _albumService;
  final ApiArtistService _artistService; // <-- THÊM MỚI
  final ApiPlaylistService _playlistService; // <-- THÊM MỚI

  // Sửa constructor để nhận service
  DataBloc({
    required ApiSongService songService,
    required ApiAlbumService albumService,
    required ApiArtistService artistService, // <-- THÊM MỚI
    required ApiPlaylistService playlistService, // <-- THÊM MỚI
  }) : _songService = songService,
       _albumService = albumService,
       _artistService = artistService, // <-- THÊM MỚI
       _playlistService = playlistService, // <-- THÊM MỚI
       super(DataLoading()) {
    on<FetchDataRequested>(_onFetchDataRequested);
  }

  Future<void> _onFetchDataRequested(
    FetchDataRequested event,
    Emitter<DataState> emit,
  ) async {
    emit(DataLoading());
    try {
      final responses = await Future.wait([
        _songService.getAllSongs(),
        _albumService.getAllAlbums(),
        _artistService.getAllArtists(),
        _playlistService.getEditorialPlaylists(),
      ]);

      List<Map<String, dynamic>> songsData = responses[0] as List<Map<String, dynamic>>;
      final albumsData = responses[1] as List<Map<String, dynamic>>;
      final artistsData = responses[2] as List<Map<String, dynamic>>;
      final playlistsData = responses[3] as List<Map<String, dynamic>>;

      // --- THÊM LOGIC "LÀM GIÀU DỮ LIỆU" ---
      // Tạo một Map để tra cứu tên album từ ID
      final Map<String, String> albumIdToNameMap = {
        for (var album in albumsData) album['id']: album['title'] ?? '',
      };

      // "Làm giàu" (enrich) danh sách bài hát
      songsData = songsData.map((song) {
        // Nếu bài hát chưa có tên album (ví dụ: từ /api/songs)
        if (song['album_name'] == null) {
          // Lấy id_album
          final albumId = song['id_album'];
          if (albumId != null && albumIdToNameMap.containsKey(albumId)) {
            // Sao chép song object và thêm trường 'album_name'
            return {...song, 'album_name': albumIdToNameMap[albumId]};
          }
        }
        return song; // Trả về bài hát gốc nếu đã có tên album hoặc không tìm thấy
      }).toList();
      // --- KẾT THÚC LOGIC "LÀM GIÀU DỮ LIỆU" ---

      emit(
        DataLoaded(
          songs: songsData, // <-- Trả về danh sách bài hát đã "làm giàu"
          albums: albumsData,
          artists: artistsData,
          playlists: playlistsData,
        ),
      );
    } catch (e) {
      // Phát ra trạng thái lỗi
      emit(DataError(e.toString()));
    }
  }
}
