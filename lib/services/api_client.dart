import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';

// Đây là file "connect" mới, thay thế cho việc gọi http trực tiếp
class ApiClient {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Hàm GET
  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse(ApiConstants.baseUrl + endpoint);
    
    try {
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      // Xử lý lỗi mạng (ví dụ: không có internet, server sập)
      print('Lỗi ApiClient.get($endpoint): $e');
      throw Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại đường truyền.');
    }
  }

  // Hàm POST (Dùng cho Auth, Like, Thêm vào playlist...)
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final uri = Uri.parse(ApiConstants.baseUrl + endpoint);
    try {
      final response = await http.post(
        uri,
        body: jsonEncode(body ?? {}), // Mã hóa body thành JSON
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      print('Lỗi ApiClient.post($endpoint): $e');
      throw Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại đường truyền.');
    }
  }

// Hàm PUT (Dùng để cập nhật)
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final uri = Uri.parse(ApiConstants.baseUrl + endpoint);
    try {
      final response = await http.put( // <-- Dùng http.put
        uri,
        body: jsonEncode(body ?? {}), 
        headers: await _getHeaders(), 
      );
      return _handleResponse(response);
    } catch (e) {
      print('Lỗi ApiClient.put($endpoint): $e');
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }

  // Hàm Tải file
  Future<dynamic> uploadFile(
    String endpoint, 
    String filePath, 
    String fileFieldName,
    {String? mimeType}
  ) async {
    final uri = Uri.parse(ApiConstants.baseUrl + endpoint);
    try {
      var request = http.MultipartRequest('POST', uri);

      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      MediaType? contentType;
      if (mimeType != null) {
        final parts = mimeType.split('/'); 
        if (parts.length == 2) {
          contentType = MediaType(parts[0], parts[1]); 
        }
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          fileFieldName, 
          filePath,
          contentType: contentType, 
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);

    } catch (e) {
      print('Lỗi ApiClient.uploadFile($endpoint): $e');
      // --- SỬA LỖI ---
      rethrow; // Ném lại lỗi gốc
      // --- KẾT THÚC SỬA ---
    }
  }


  // --- HÀM TRỢ GIÚP ---

  // Quản lý header tập trung
  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    
    // Đọc token từ storage
    final token = await _secureStorage.read(key: 'auth_token');
    
    // Nếu có token, thêm vào header
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Xử lý response tập trung
  dynamic _handleResponse(http.Response response) {
    // Giải mã UTF-8 để hiển thị đúng tiếng Việt
    final responseBody = utf8.decode(response.bodyBytes);
    final data = jsonDecode(responseBody);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Thành công
      return data;
    } else {
      // Thất bại (404, 500, 401...)
      print('Lỗi API: ${response.statusCode} - ${responseBody}');
      throw Exception('Lỗi từ máy chủ: ${response.statusCode}');
    }
  }
}
