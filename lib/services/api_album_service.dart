// lib/services/api_album_service.dart
import 'api_constants.dart';
import 'api_client.dart'; // Import ApiClient
import 'api_mapper.dart'; // Import mapper

class ApiAlbumService {
  final ApiClient _apiClient;
  ApiAlbumService(this._apiClient); // Yêu cầu ApiClient khi khởi tạo

  // Lấy tất cả album
  Future<List<Map<String, dynamic>>> getAllAlbums() async {
    try {
      // 1. Lấy dữ liệu thô
      final List<dynamic> rawData = await _apiClient.get(ApiConstants.albums);
      
      // 2. Chuyển đổi
      final List<Map<String, dynamic>> apiAlbumsList = 
          List<Map<String, dynamic>>.from(rawData);

      // 3. "Dịch" (map) từng album
      final List<Map<String, dynamic>> appAlbumsList = 
          apiAlbumsList.map((apiAlbum) => mapApiAlbum(apiAlbum)).toList();
          
      // 4. Trả về
      return appAlbumsList;
    } catch (e) {
      print('Lỗi ApiAlbumService.getAllAlbums: $e');
      rethrow;
    }
  }

  // Lấy chi tiết MỘT album (bao gồm danh sách bài hát)
  Future<Map<String, dynamic>> getAlbumById(String albumId) async {
    try {
      // 1. Gọi API lấy chi tiết album (ví dụ: /api/albums/123)
      final Map<String, dynamic> apiAlbum = await _apiClient.get(
        '${ApiConstants.albums}/$albumId'
      );
      
      // 2. "Dịch" (map) album đó sang định dạng App hiểu
      // (Hàm mapApiAlbum cũng sẽ dịch các bài hát con bên trong)
      final Map<String, dynamic> appAlbum = mapApiAlbum(apiAlbum);
      
      // 3. Trả về
      return appAlbum;
    } catch (e) {
      print('Lỗi ApiAlbumService.getAlbumById: $e');
      rethrow;
    }
  }

  // Hàm này của bạn giữ nguyên (dù có thể không cần nữa)
  Future<List<dynamic>> getSongsByAlbumId(String albumId) async {
     try {
      final response = await _apiClient.get(
        '${ApiConstants.albums}/$albumId/songs'
      );
      // Bạn nên map kết quả này bằng mapApiSong nếu dùng
      return response as List<dynamic>;
    } catch (e) {
      print('Lỗi ApiAlbumService.getSongsByAlbumId: $e');
      rethrow;
    }
  }
}