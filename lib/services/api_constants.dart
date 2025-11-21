class ApiConstants {
  // Đây chính là URL public
  static const String baseUrl = 'https://buzzify-backend.genzo.io.vn';

  // Các đường dẫn (endpoints)
  static const String songs = '/api/songs';
  static const String albums = '/api/albums';
  static const String playlists = '/api/playlists';
  static const String artists = '/api/artists';
  static const String search = '/api/search';

  // --- THÊM CÁC DÒNG NÀY ---
  static const String authRegister = '/api/auth/register';
  static const String authVerify = '/api/auth/verify-email';
  static const String authLogin = '/api/auth/login';
  static const String authGoogle = '/api/auth/google';
  static const String authResendOtp = '/api/auth/resend-otp';
  static const String authForgotPassword = '/api/auth/forgot-password';
  static const String authResetPassword = '/api/auth/reset-password';

  // API này trỏ đến /api/playlists/user/ (backend sẽ thêm /:userId/created)
  static const String userPlaylists = '/api/playlists/user';

  static const String fileUpload = '/api/files/upload'; // Dùng cho (POST)
  static const String authUpdateProfile = '/api/auth/profile'; // Dùng cho (PUT)

  static const String authMyAvatar = '/api/auth/my-avatar';
}
