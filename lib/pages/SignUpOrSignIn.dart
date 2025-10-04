import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/common/app_vectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:buzzify/pages/signup.dart';
import 'package:buzzify/pages/signin.dart';

class SignupOrSigninPage extends StatefulWidget {
  const SignupOrSigninPage({super.key});

  @override
  State<SignupOrSigninPage> createState() => _SignupOrSigninPageState();
}

class _SignupOrSigninPageState extends State<SignupOrSigninPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: SvgPicture.asset(AppVectors.topPattern, fit: BoxFit.contain),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: SvgPicture.asset(
              AppVectors.bottomPattern,
              fit: BoxFit.contain,
            ),
          ),
          // Form
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      SvgPicture.asset(
                        AppVectors.logo,
                        height: 220, // Giới hạn chiều cao để tránh overflow
                        fit: BoxFit.contain,
                      ),

                      // Title text
                      const Text(
                        'Sống trọn từng giai điệu',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Buzzify – ứng dụng âm nhạc cá nhân hóa, kết nối cộng đồng yêu nhạc. Đăng ký dễ dàng, khám phá thế giới âm nhạc không giới hạn.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),
                      CustomElevateButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage(),),
                          );
                        },
                        title: 'Đăng ký',
                      ),
                      const SizedBox(height: 20),
                      CustomOutlinedButton(
                        title: 'Đăng nhập',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SigninPage(),),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomElevateButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const CustomElevateButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        backgroundColor: AppColors.primary,
        minimumSize: Size.fromHeight(60),
      ),
    );
  }
}

class CustomOutlinedButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final Widget? icon;
  final Color textColor;
  final Color borderColor;

  const CustomOutlinedButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.icon,
    this.textColor = AppColors.grey,
    this.borderColor = AppColors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        side: BorderSide(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 15),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
