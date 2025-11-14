// lib/services/api_song_service.dart
import 'api_constants.dart';
import 'api_client.dart'; // Import ApiClient
import 'api_mapper.dart'; // Import mapper

class ApiSongService {
  final ApiClient _apiClient;
  ApiSongService(this._apiClient); // Yêu cầu ApiClient khi khởi tạo

  // Lấy tất cả bài hát
  Future<List<Map<String, dynamic>>> getAllSongs() async {
    try {
      // 1. Lấy dữ liệu thô (List<dynamic>) từ API
      final List<dynamic> rawData = await _apiClient.get(ApiConstants.songs);
      
      // 2. Chuyển đổi dữ liệu thô sang List<Map<String, dynamic>>
      final List<Map<String, dynamic>> apiSongsList = 
          List<Map<String, dynamic>>.from(rawData);

      // 3. "Dịch" (map) từng bài hát sang định dạng App hiểu
      final List<Map<String, dynamic>> appSongsList = 
          apiSongsList.map((apiSong) => mapApiSong(apiSong)).toList();
          
      // 4. Trả về danh sách đã dịch
      return appSongsList;
    } catch (e) {
      print('Lỗi ApiSongService.getAllSongs: $e');
      rethrow;
    }
  }
}