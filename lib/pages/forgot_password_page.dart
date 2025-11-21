// lib/pages/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:buzzify/controllers/auth_controller.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/pages/SignUpOrSignIn.dart';
import 'package:buzzify/pages/signin.dart';

class ForgotPasswordPage extends StatefulWidget {
  // Nhận email (nếu có) từ trang Đăng nhập
  final String? initialEmail; 
  const ForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Tự động điền email nếu được truyền vào
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    // Gọi hàm controller
    await AuthController.forgotPassword(
      context: context,
      email: _emailController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: const CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),
                    const Text(
                      "Quên mật khẩu",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nhập email của bạn để nhận mã OTP đặt lại mật khẩu.', 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 40),

                    // TextFormField Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 25,
                          horizontal: 22,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập Email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Nút Gửi
                    CustomElevateButton(
                      title: 'Gửi mã',
                      onPressed: _handleForgotPassword,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}