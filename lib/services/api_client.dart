import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

// Đây là file "connect" mới, thay thế cho việc gọi http trực tiếp
class ApiClient {
  
  // Hàm GET
  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse(ApiConstants.baseUrl + endpoint);
    try {
      final response = await http.get(
        uri,
        headers: _getHeaders(),
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
        body: jsonEncode(body), // Mã hóa body thành JSON
        headers: _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      print('Lỗi ApiClient.post($endpoint): $e');
      throw Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại đường truyền.');
    }
  }

  // (Thêm các hàm PUT, DELETE tương tự nếu cần)

  // --- HÀM TRỢ GIÚP ---

  // Quản lý header tập trung
  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    
    // NẾU CÓ AUTH: Sửa lại hàm này để lấy token (từ Bloc hoặc SharedPreferences)
    // if (token != null) {
    //   headers['Authorization'] = 'Bearer $token';
    // }
    
    return headers;
  }

  // Xử lý response tập trung
  dynamic _handleResponse(http.Response response) {
    // Giải mã UTF-8 để hiển thị đúng tiếng Việt
    final responseBody = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Thành công
      return jsonDecode(responseBody);
    } else {
      // Thất bại (404, 500, 401...)
      print('Lỗi API: ${response.statusCode} - ${responseBody}');
      throw Exception('Lỗi từ máy chủ: ${response.statusCode}');
    }
  }
}
