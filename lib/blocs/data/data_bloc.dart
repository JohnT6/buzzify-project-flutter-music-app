// lib/blocs/data/data_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

// Import các service
import 'package:buzzify/services/api_song_service.dart';
import 'package:buzzify/services/api_album_service.dart';
import 'package:buzzify/services/api_artist_service.dart';
import 'package:buzzify/services/api_playlist_service.dart';

part 'data_event.dart';
part 'data_state.dart';

class DataBloc extends Bloc<DataEvent, DataState> {
  // Dùng service
  final ApiSongService _songService;
  final ApiAlbumService _albumService;
  final ApiArtistService _artistService;
  final ApiPlaylistService _playlistService;

  // Constructor nhận service
  DataBloc({
    required ApiSongService songService,
    required ApiAlbumService albumService,
    required ApiArtistService artistService,
    required ApiPlaylistService playlistService,
  }) : _songService = songService,
       _albumService = albumService,
       _artistService = artistService,
       _playlistService = playlistService,
       super(DataLoading()) {
    on<FetchDataRequested>(_onFetchDataRequested);
    on<ToggleLikeSong>(_onToggleLikeSong); // <-- Đăng ký sự kiện Like mới
  }

  Future<void> _onFetchDataRequested(
    FetchDataRequested event,
    Emitter<DataState> emit,
  ) async {
    emit(DataLoading());
    try {
      // 1. Tạo danh sách các API cần gọi song song
      final futures = <Future>[
        _songService.getAllSongs(),             // [0]
        _albumService.getAllAlbums(),           // [1]
        _artistService.getAllArtists(),         // [2]
        _playlistService.getEditorialPlaylists(), // [3]
      ];

      // 2. Nếu có userId (đã đăng nhập), gọi thêm API lấy playlist yêu thích
      if (event.userId != null) {
        futures.add(_playlistService.getLikedSongsPlaylist(event.userId!)); // [4]
      }

      // 3. Chờ tất cả hoàn thành
      final responses = await Future.wait(futures);

      // 4. Lấy dữ liệu từ kết quả
      var songsData = responses[0] as List<Map<String, dynamic>>;
      final albumsData = responses[1] as List<Map<String, dynamic>>;
      final artistsData = responses[2] as List<Map<String, dynamic>>;
      final playlistsData = responses[3] as List<Map<String, dynamic>>;

      // 5. Xử lý danh sách ID bài hát đã thích (Nếu có kết quả thứ 5)
      Set<String> likedIds = {};
      if (event.userId != null && responses.length > 4) {
        try {
          // API trả về Playlist Object -> lấy mảng 'songs' bên trong
          final likedPlaylist = responses[4] as Map<String, dynamic>;
          final likedSongs = likedPlaylist['songs'] as List<dynamic>?;
          
          if (likedSongs != null) {
            // Tạo Set ID để tra cứu cho nhanh (O(1))
            likedIds = likedSongs.map((s) => s['id'].toString()).toSet();
          }
        } catch (e) {
          print("Lỗi parse danh sách yêu thích: $e");
          // Không throw lỗi để app vẫn chạy được các phần khác
        }
      }

      // --- LOGIC "LÀM GIÀU DỮ LIỆU" ---
      // Tạo Map để tra cứu tên album nhanh
      final Map<String, String> albumIdToNameMap = {
        for (var album in albumsData) album['id']: album['title'] ?? '',
      };

      // Gán tên album vào bài hát nếu thiếu
      songsData = songsData.map((song) {
        if (song['album_name'] == null) {
          final albumId = song['id_album'];
          if (albumId != null && albumIdToNameMap.containsKey(albumId)) {
            return {...song, 'album_name': albumIdToNameMap[albumId]};
          }
        }
        return song;
      }).toList();
      // --- KẾT THÚC LOGIC ---

      emit(
        DataLoaded(
          songs: songsData,
          albums: albumsData,
          artists: artistsData,
          playlists: playlistsData,
          likedSongIds: likedIds, // <-- Truyền danh sách ID đã thích vào State
        ),
      );
    } catch (e) {
      emit(DataError(e.toString()));
    }
  }

  // --- HÀM MỚI: XỬ LÝ LIKE/UNLIKE ---
  Future<void> _onToggleLikeSong(
    ToggleLikeSong event,
    Emitter<DataState> emit,
  ) async {
    // Chỉ xử lý khi dữ liệu đã tải xong
    if (state is DataLoaded) {
      final currentState = state as DataLoaded;
      
      // Tạo bản sao của Set cũ để sửa đổi
      final currentLikedIds = Set<String>.from(currentState.likedSongIds);
      
      // Cập nhật Optimistic (Cập nhật giao diện ngay lập tức)
      if (currentLikedIds.contains(event.songId)) {
        currentLikedIds.remove(event.songId); // Nếu có rồi thì xóa (Unlike)
      } else {
        currentLikedIds.add(event.songId); // Chưa có thì thêm (Like)
      }
      
      // Emit state mới để UI cập nhật icon trái tim
      emit(currentState.copyWith(likedSongIds: currentLikedIds));

      try {
        // Gọi API cập nhật server ngầm bên dưới
        await _songService.toggleLike(event.songId);
      } catch (e) {
        print("Lỗi toggle like API: $e");
        // Nếu API lỗi, có thể revert lại state ở đây nếu muốn chặt chẽ
        // (Hiện tại chỉ log ra console để trải nghiệm mượt mà)
      }
    }
  }
}