// import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AuthService {
  // Đăng nhập bằng email và mật khẩu
  static Future<AuthResponse> signInWithEmail(String email, String password) {
    return supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Đăng ký tài khoản mới
  static Future<AuthResponse> signUp(String email, String password)  {
    // Tên người dùng sẽ được tự động lấy từ phần đầu của email
    String autoName = email.trim().split('@').first;
    // Cho viết hoa chữ cái đầu và cắt chuỗi từ ký tự thứ 2 gép vào
    autoName = autoName[0].toUpperCase() + autoName.substring(1);

// final response = 

    return supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': autoName, 'display_name': autoName},
    );

    // // Tạo mã OTP
    // final otp = (100000 + Random().nextInt(899999)).toString();

    // // Lưu mã OTP vào Supabase
    // await supabase.from('email_otps').insert({
    //   'email': email,
    //   'otp': otp,
    //   'expires_at': DateTime.now()
    //       .add(const Duration(minutes: 10))
    //       .toIso8601String(),
    // });

    // await supabase.functions.invoke(
    //   'send-otp-email',
    //   body: {'email': email.trim(), 'otp': otp},
    // );

    // return response;
  }

  // Đăng nhập bằng Google
  static Future<AuthResponse> signInWithGoogle({
    required String idToken,
    required String accessToken,
  }) {
    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  // Đăng xuất khỏi tài khoản hiện tại
  static Future<void> signOut() {
    return supabase.auth.signOut();
  }

  // Lấy session hiện tại
  static Session? getCurrentSession() {
    return supabase.auth.currentSession;
  }

  // Lấy thông tin user hiện tại
  static User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // static Future<bool> verifyOtp(String email, String otp) async {
  //   final response = await supabase
  //       .from('email_otps')
  //       .select()
  //       .eq('email', email.trim())
  //       .eq('otp', otp.trim())
  //       .maybeSingle();

  //   return response != null;
  // }
}
