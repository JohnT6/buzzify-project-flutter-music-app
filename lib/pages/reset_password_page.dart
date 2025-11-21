// lib/pages/reset_password_page.dart
import 'package:flutter/material.dart';
import 'package:buzzify/controllers/auth_controller.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/pages/SignUpOrSignIn.dart';
import 'package:buzzify/pages/signin.dart';

class ResetPasswordPage extends StatefulWidget {
  // Phải có email
  final String email; 
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _obscurePassWord = true;
  bool _obscureConfirmPassWord = true;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    await AuthController.resetPassword(
      context: context,
      email: widget.email,
      otp: _otpController.text.trim(),
      newPassword: _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // (Copy hàm validate mật khẩu từ signup.dart)
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigit = value.contains(RegExp(r'\d'));
    final hasSpecial = value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    if (!hasUppercase || !hasLowercase || !hasDigit || !hasSpecial) {
      return 'Mật khẩu phải có chữ hoa, chữ thường, số và ký tự đặc biệt';
    }
    return null;
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
                      "Tạo mật khẩu mới",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // TextFormField OTP
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Mã OTP (6 số)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 25,
                          horizontal: 22,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length != 6) {
                          return 'OTP phải có 6 chữ số';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // TextFormField Mật khẩu mới
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassWord,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 25,
                          horizontal: 22,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassWord = !_obscurePassWord),
                          icon: Icon(_obscurePassWord ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    
                    // TextFormField Xác nhận
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassWord,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 25,
                          horizontal: 22,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscureConfirmPassWord = !_obscureConfirmPassWord),
                          icon: Icon(_obscureConfirmPassWord ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    CustomElevateButton(
                      title: 'Đặt lại mật khẩu',
                      onPressed: _handleResetPassword,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}