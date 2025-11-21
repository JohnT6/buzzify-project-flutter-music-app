// lib/services/api_artist_service.dart
import 'api_constants.dart';
import 'api_client.dart'; 
import 'api_mapper.dart'; 

class ApiArtistService {
  final ApiClient _apiClient;
  ApiArtistService(this._apiClient);

  // Lấy tất cả nghệ sĩ (Đã có)
  Future<List<Map<String, dynamic>>> getAllArtists() async {
    try {
      final List<dynamic> rawData = await _apiClient.get(ApiConstants.artists);
      final List<Map<String, dynamic>> apiArtistsList = 
          List<Map<String, dynamic>>.from(rawData);
      final List<Map<String, dynamic>> appArtistsList = 
          apiArtistsList.map((apiArtist) => mapApiArtist(apiArtist)).toList();
      return appArtistsList;
    } catch (e) {
      print('Lỗi ApiArtistService.getAllArtists: $e');
      rethrow;
    }
  }

  // --- THÊM 2 HÀM MỚI ---

  // Lấy các bài hát (phổ biến) của 1 nghệ sĩ
  Future<List<Map<String, dynamic>>> getSongsByArtistId(String artistId) async {
    try {
      final List<dynamic> rawData = await _apiClient.get(
        '${ApiConstants.artists}/$artistId/songs'
      );
      final List<Map<String, dynamic>> apiSongsList = 
          List<Map<String, dynamic>>.from(rawData);
      // Dùng mapApiSong để dịch
      final List<Map<String, dynamic>> appSongsList = 
          apiSongsList.map((apiSong) => mapApiSong(apiSong)).toList();
      return appSongsList;
    } catch (e) {
      print('Lỗi ApiArtistService.getSongsByArtistId: $e');
      rethrow;
    }
  }

  // Lấy các album của 1 nghệ sĩ
  Future<List<Map<String, dynamic>>> getAlbumsByArtistId(String artistId) async {
    try {
      final List<dynamic> rawData = await _apiClient.get(
        '${ApiConstants.artists}/$artistId/albums'
      );
      final List<Map<String, dynamic>> apiAlbumsList = 
          List<Map<String, dynamic>>.from(rawData);
      // Dùng mapApiAlbum để dịch
      final List<Map<String, dynamic>> appAlbumsList = 
          apiAlbumsList.map((apiAlbum) => mapApiAlbum(apiAlbum)).toList();
      return appAlbumsList;
    } catch (e) {
      print('Lỗi ApiArtistService.getAlbumsByArtistId: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getArtistById(String artistId) async {
    try {
      final Map<String, dynamic> rawData = await _apiClient.get(
        '${ApiConstants.artists}/$artistId'
      );
      return mapApiArtist(rawData);
    } catch (e) {
      print('Lỗi ApiArtistService.getArtistById: $e');
      rethrow;
    }
  }
}