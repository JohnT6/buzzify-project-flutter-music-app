import 'package:flutter/material.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/pages/splash.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Buzzify",
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.darkBackground,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ), 
      home: const SplashPage(),
    );
  }
}
