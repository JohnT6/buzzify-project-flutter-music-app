import 'package:buzzify/common/app_vectors.dart';
import 'package:buzzify/pages/SignUpOrSignIn.dart';
import 'package:buzzify/supabase/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: SvgPicture.asset(AppVectors.logo)),
      body: Center(
        child: CustomOutlinedButton(title: "Đăng xuất", onPressed: () => AuthController.signOut(context)),
      ),
    );
  }
}