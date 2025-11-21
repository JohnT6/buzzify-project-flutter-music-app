// lib/pages/splash.dart
import 'package:buzzify/blocs/auth/auth_bloc.dart'; // <-- Dùng AuthBloc
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buzzify/common/app_vectors.dart';
import 'package:buzzify/pages/SignUpOrSignIn.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // <-- XÓA
import 'package:flutter_bloc/flutter_bloc.dart'; 

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // Không cần Supabase ở đây
  // final supabase = Supabase.instance.client; // <-- XÓA

  @override
  void initState() {
    super.initState();
    _redirect(); // Gọi hàm chuyển hướng
  }

  // Hàm _redirect mới (thay thế cho _checkAuthStatus)
  Future<void> _redirect() async {
    // Chờ 2 giây để hiển thị logo
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Lấy trạng thái từ AuthBloc
    // Dùng context.read() vì nó ở trong initState (chỉ gọi 1 lần)
    final authState = context.read<AuthBloc>().state;

    // Điều hướng dựa trên trạng thái đã lưu
    if (authState.status == AuthStatus.authenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // Bất kể là unknown, unauthenticated, hay needsVerification
      // đều đẩy về trang đăng nhập
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignupOrSigninPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Thêm BlocListener để xử lý nếu trạng thái thay đổi BẤT NGỜ
    // (ví dụ: người dùng bị đăng xuất từ server)
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Nếu state chuyển về unauthenticated (ví dụ: logout ở đâu đó)
        // thì đá về trang đăng nhập
        if (state.status == AuthStatus.unauthenticated) {
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(builder: (context) => const SignupOrSigninPage()),
             (route) => false,
           );
        }
        // Nếu state chuyển về authenticated (ví dụ: xác thực OTP thành công)
        else if (state.status == AuthStatus.authenticated) {
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(builder: (context) => const HomePage()),
             (route) => false,
           );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground, // Thêm màu nền
        body: Center(child: SvgPicture.asset(AppVectors.logo))
      ),
    );
  }
}