// lib/services/api_playlist_service.dart
import 'api_constants.dart';
import 'api_client.dart'; 
import 'api_mapper.dart'; 

class ApiPlaylistService {
  final ApiClient _apiClient;
  ApiPlaylistService(this._apiClient);

  // Lấy các playlist "editorial"
  Future<List<Map<String, dynamic>>> getEditorialPlaylists() async {
    try {
      // Dùng endpoint /api/playlists (API đã trỏ route / về editorial)
      final List<dynamic> rawData = await _apiClient.get(ApiConstants.playlists);
      
      final List<Map<String, dynamic>> apiPlaylistsList = 
          List<Map<String, dynamic>>.from(rawData);

      final List<Map<String, dynamic>> appPlaylistsList = 
          apiPlaylistsList.map((apiPlaylist) => mapApiPlaylist(apiPlaylist)).toList();
          
      return appPlaylistsList;
    } catch (e) {
      print('Lỗi ApiPlaylistService.getEditorialPlaylists: $e');
      rethrow;
    }
  }

  // --- THÊM HÀM MỚI NÀY ---
  // Lấy chi tiết MỘT playlist (bao gồm danh sách bài hát)
  Future<Map<String, dynamic>> getPlaylistById(String playlistId) async {
    try {
      // 1. Gọi API (ví dụ: /api/playlists/pl-123)
      // API backend này trả về cả thông tin playlist VÀ danh sách 'songs'
      final Map<String, dynamic> apiPlaylist = await _apiClient.get(
        '${ApiConstants.playlists}/$playlistId'
      );
      
      // 2. "Dịch" (map) playlist đó sang định dạng App hiểu
      // (Hàm mapApiPlaylist cần được cập nhật để dịch cả 'songs' bên trong)
      final Map<String, dynamic> appPlaylist = mapApiPlaylist(apiPlaylist);
      
      // 3. Trả về
      return appPlaylist;
    } catch (e) {
      print('Lỗi ApiPlaylistService.getPlaylistById: $e');
      rethrow;
    }
  }

  // Lấy các playlist do 1 người dùng tạo
  Future<List<Map<String, dynamic>>> getUserCreatedPlaylists(String userId) async {
    try {
      // Sẽ gọi: /api/playlists/user/USER_ID/created
      final List<dynamic> rawData = await _apiClient.get(
        '${ApiConstants.userPlaylists}/$userId/created'
      );
      
      final List<Map<String, dynamic>> apiPlaylistsList = 
          List<Map<String, dynamic>>.from(rawData);

      // Dùng mapper (nó sẽ không có 'songs' bên trong, nhưng vẫn ổn)
      final List<Map<String, dynamic>> appPlaylistsList = 
          apiPlaylistsList.map((apiPlaylist) => mapApiPlaylist(apiPlaylist)).toList();
          
      return appPlaylistsList;
    } catch (e) {
      print('Lỗi ApiPlaylistService.getUserCreatedPlaylists: $e');
      rethrow;
    }
  }

  // GET /api/playlists/user/:userId/liked-songs
  // Lấy playlist "Bài hát đã thích" của người dùng
  Future<Map<String, dynamic>> getLikedSongsPlaylist(String userId) async {
    try {
      final dynamic rawData = await _apiClient.get(
        '${ApiConstants.userPlaylists}/$userId/liked-songs'
      );
      
      // Map dữ liệu playlist + songs
      return mapApiPlaylist(rawData); 
    } catch (e) {
      print('Lỗi ApiPlaylistService.getLikedSongsPlaylist: $e');
      // Trả về map rỗng hoặc rethrow tùy ý
      rethrow;
    }
  }
}