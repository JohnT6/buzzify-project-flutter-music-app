// lib/controllers/auth_controller.dart
import 'package:buzzify/blocs/auth/auth_bloc.dart'; // <-- THÊM
import 'package:buzzify/models/user.dart'; // <-- THÊM
import 'package:buzzify/pages/VerifyOtpPage.dart';
import 'package:buzzify/pages/SignUpOrSignIn.dart';
import 'package:buzzify/pages/signin.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:buzzify/services/api_auth_service.dart'; 
import 'package:buzzify/pages/home.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:buzzify/pages/reset_password_page.dart';

class AuthController {

  // Hàm private để hiển thị lỗi
  static void _showError(BuildContext context, dynamic e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'), 
        backgroundColor: Colors.red
      ),
    );
  }
  
  // Đăng nhập bằng Email
  static Future<void> signInWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      final authService = context.read<ApiAuthService>();
      final data = await authService.login(email, password); // Gọi API
      
      // Tạo User object từ data trả về
      final user = User.fromJson(data['user']);
      
      // Báo cho AuthBloc biết user đã thay đổi
      context.read<AuthBloc>().add(AuthUserChanged(user));

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false
      );
    } catch (e) {
      if (!context.mounted) return;
      if (e.toString().contains('Vui lòng xác thực')) {
         // Báo cho AuthBloc biết cần xác thực
         context.read<AuthBloc>().add(AuthNeedsVerification(email));
         Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => VerifyOtpPage(email: email)
        ));
      } else {
        _showError(context, e);
      }
    }
  }

  // Đăng nhập bằng Google
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      const webClientId = '744107466365-0koqtc5brk8k5ietfv5td0f2evig67i7.apps.googleusercontent.com'; // ID cũ của bạn

      final googleSignIn = GoogleSignIn(serverClientId: webClientId);
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) throw 'Đăng nhập Google đã bị hủy';

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) throw 'Không thể lấy thông tin từ Google';
      
      final authService = context.read<ApiAuthService>();
      final data = await authService.googleSignIn(idToken); 

      // Tạo User object và báo cho BLoC
      final user = User.fromJson(data['user']);
      context.read<AuthBloc>().add(AuthUserChanged(user));

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, e);
    }
  }

  // Đăng ký tài khoản
  static Future<void> signUp({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      final authService = context.read<ApiAuthService>();
      await authService.register(email, password);

      if (!context.mounted) return;
      
      // Báo cho AuthBloc biết cần xác thực
      context.read<AuthBloc>().add(AuthNeedsVerification(email));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công! Vui lòng kiểm tra email.'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VerifyOtpPage(email: email)
      ));
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, e);
    }
  }

  // Xác thực OTP
  static Future<void> verifyOtp({
    required BuildContext context,
    required String email,
    required String otp,
  }) async {
     try {
      final authService = context.read<ApiAuthService>();
      final data = await authService.verifyOtp(email, otp);
      
      // Tạo User object và báo cho BLoC
      final user = User.fromJson(data['user']);
      context.read<AuthBloc>().add(AuthUserChanged(user));

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, e);
    }
  }

  // Gửi lại OTP
  static Future<void> resendOtp({
    required BuildContext context,
    required String email,
  }) async {
     try {
      final authService = context.read<ApiAuthService>();
      final data = await authService.resendOtp(email);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Đã gửi lại mã OTP.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, e);
    }
  }

  // 1. Quên mật khẩu
  static Future<void> forgotPassword({
    required BuildContext context,
    required String email,
  }) async {
     try {
      final authService = context.read<ApiAuthService>();
      final data = await authService.forgotPassword(email);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Đã gửi mã OTP. Vui lòng kiểm tra email.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Chuyển sang trang Reset Password
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResetPasswordPage(email: email),
      ));

    } catch (e) {
      if (!context.mounted) return;
      _showError(context, e);
    }
  }

  // 2. Đặt lại mật khẩu
  static Future<void> resetPassword({
    required BuildContext context,
    required String email,
    required String otp,
    required String newPassword,
  }) async {
     try {
      final authService = context.read<ApiAuthService>();
      final data = await authService.resetPassword(email, otp, newPassword);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Đổi mật khẩu thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Đổi thành công, quay về trang Đăng nhập
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SigninPage()),
        (route) => route.isFirst, // Xóa các trang (Reset, Forgot)
      );

    } catch (e) {
      if (!context.mounted) return;
      _showError(context, e);
    }
  }

  // --- HÀM SỬA LỖI (ĐÃ THÊM) ---
  static Future<bool> updateProfile({
    required BuildContext context,
    String? hoTen,
    String? anhDaiDien,
  }) async {
     try {
      final authService = context.read<ApiAuthService>();
      
      if (hoTen == null && anhDaiDien == null) {
        return true; 
      }
      
      final data = await authService.updateProfile(hoTen: hoTen, anhDaiDien: anhDaiDien);

      // Cập nhật lại user trong AuthBloc
      final user = User.fromJson(data['user']);
      context.read<AuthBloc>().add(AuthUserChanged(user));

      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Cập nhật thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      return true; // Trả về true nếu thành công

    } catch (e) {
      if (!context.mounted) return false;
      _showError(context, e); 
      return false; // Trả về false nếu thất bại
    }
  }

  // Đăng xuất
  static Future<void> signOut(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final audioBloc = context.read<AudioPlayerBloc>();
    // final authService = context.read<ApiAuthService>(); // Không cần gọi
    final authBloc = context.read<AuthBloc>(); // Lấy BLoC
    
    try {
      audioBloc.add(LogoutReset());
      // Bắn event đăng xuất (BLoC sẽ tự xóa token)
      authBloc.add(AuthLogoutRequested()); 

      if (!context.mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) =>  const SignupOrSigninPage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, e);
    }
  }
}