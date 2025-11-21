// lib/services/api_auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'api_constants.dart';

class ApiAuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  // Key để lưu token
  static const String _tokenKey = 'auth_token';

  ApiAuthService(this._apiClient, this._secureStorage);

  // Lưu token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  // Đọc token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Xóa token (Đăng xuất)
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // --- Các hàm gọi API ---

  // 1. Đăng ký
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final data = await _apiClient.post(
        ApiConstants.authRegister,
        body: {'email': email, 'password': password},
      );
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Lỗi ApiAuthService.register: $e');
      rethrow;
    }
  }

  // 2. Xác thực OTP
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final data = await _apiClient.post(
        ApiConstants.authVerify,
        body: {'email': email, 'otp': otp},
      );
      // Khi xác thực thành công, API trả về token, chúng ta lưu nó
      final token = data?['token'];
      if (token != null) {
        await saveToken(token);
      }
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Lỗi ApiAuthService.verifyOtp: $e');
      rethrow;
    }
  }

  // 3. Đăng nhập
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final data = await _apiClient.post(
        ApiConstants.authLogin,
        body: {'email': email, 'password': password},
      );
      // Khi đăng nhập thành công, API trả về token, chúng ta lưu nó
      final token = data?['token'];
      if (token != null) {
        await saveToken(token);
      }
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Lỗi ApiAuthService.login: $e');
      rethrow;
    }
  }
  
  // 4. Đăng nhập Google
  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
     try {
      final data = await _apiClient.post(
        ApiConstants.authGoogle,
        body: {'idToken': idToken},
      );
      // Khi đăng nhập thành công, API trả về token, chúng ta lưu nó
      final token = data?['token'];
      if (token != null) {
        await saveToken(token);
      }
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Lỗi ApiAuthService.googleSignIn: $e');
      rethrow;
    }
  }

  // 5. Gửi lại OTP
  Future<Map<String, dynamic>> resendOtp(String email) async {
    try {
      final data = await _apiClient.post(
        ApiConstants.authResendOtp,
        body: {'email': email},
      );
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Lỗi ApiAuthService.resendOtp: $e');
      rethrow;
    }
  }

  // 6. Quên mật khẩu (Yêu cầu OTP)
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final data = await _apiClient.post(
        ApiConstants.authForgotPassword,
        body: {'email': email},
      );
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Lỗi ApiAuthService.forgotPassword: $e');
      rethrow;
    }
  }

  // 7. Đặt lại mật khẩu
  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    try {
      final data = await _apiClient.post(
        ApiConstants.authResetPassword,
        body: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword
        },
      );
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Lỗi ApiAuthService.resetPassword: $e');
      rethrow;
    }
  }

 // 8. Cập nhật hồ sơ
  Future<Map<String, dynamic>> updateProfile({String? hoTen, String? anhDaiDien}) async {
    try {
      final Map<String, dynamic> body = {};
      if (hoTen != null) {
        body['ho_ten'] = hoTen;
      }
      if (anhDaiDien != null) {
        body['anh_dai_dien'] = anhDaiDien;
      }

      if (body.isEmpty) {
        throw Exception("Không có thông tin nào để cập nhật.");
      }

      final data = await _apiClient.put( // <-- Dùng PUT
        // Sửa: Gọi đúng API Profile
        ApiConstants.authUpdateProfile, 
        body: body,
      );
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Lỗi ApiAuthService.updateProfile: $e');
      rethrow;
    }
  }
}