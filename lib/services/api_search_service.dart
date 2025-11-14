// lib/services/api_search_service.dart
import 'api_constants.dart';
import 'api_client.dart'; 
import 'api_mapper.dart'; // Dùng chung mapper

class ApiSearchService {
  final ApiClient _apiClient;
  ApiSearchService(this._apiClient);

  Future<List<Map<String, dynamic>>> search(String query) async {
    if (query.isEmpty) {
      return []; // Trả về rỗng nếu không tìm gì
    }
    
    try {
      final encodedQuery = Uri.encodeComponent(query);
      
      // 1. Gọi API: /api/search?q=...
      final List<dynamic> rawData = await _apiClient.get(
        '${ApiConstants.search}?q=$encodedQuery'
      );
      
      final List<Map<String, dynamic>> apiResults = 
          List<Map<String, dynamic>>.from(rawData);

      // 2. "Dịch" kết quả
      final List<Map<String, dynamic>> appResults = apiResults.map((item) {
        // API trả về: type, id, title, anh_bia, subtitle
        // Dùng mapper để chuyển đổi
        switch (item['type']) {
          case 'song':
            return mapApiSong(item);
          case 'album':
            return mapApiAlbum(item);
          case 'artist':
            return mapApiArtist(item);
          case 'playlist':
            return mapApiPlaylist(item);
          case 'profile':
            return mapApiProfile(item);
          default:
            return <String, dynamic>{}; // Bỏ qua
        }
      }).where((item) => item.isNotEmpty).toList(); // Lọc bỏ kết quả rỗng
          
      return appResults;
    } catch (e) {
      print('Lỗi ApiSearchService.search: $e');
      rethrow;
    }
  }
}