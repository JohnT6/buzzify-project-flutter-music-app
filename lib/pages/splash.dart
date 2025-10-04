import 'package:buzzify/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buzzify/common/app_vectors.dart';
import 'package:buzzify/pages/SignUpOrSignIn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

Future<void> _checkAuthStatus() async {
  await Future.delayed(const Duration(seconds: 1));

  if(!mounted) return;

  final session = supabase.auth.currentSession;

  if (session != null) {
      // Đã đăng nhập rồi thì qua trang home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // Chưa đăng nhập thì vào trong SignInOrSignUp
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignupOrSigninPage()),
      );
    }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: SvgPicture.asset(AppVectors.logo)));
  }
}
