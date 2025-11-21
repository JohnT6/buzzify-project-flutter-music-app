import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/common/app_vectors.dart';
import 'package:buzzify/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buzzify/pages/SignUpOrSignIn.dart';
import 'package:buzzify/pages/signin.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassWord = true;
  bool _obscureConfirmPassWord = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    await AuthController.signUp(
      context: context,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (mounted)
      setState(() {
        _isLoading = false;
      });
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });

    await AuthController.signInWithGoogle(context);

    if (mounted)
      setState(() {
        _isLoading = false;
      });
  }

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
      appBar: CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      "Đăng ký",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // TextFlied Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: EdgeInsets.symmetric(
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
                    const SizedBox(height: 16),

                    // TextFlied Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassWord,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 25,
                          horizontal: 22,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassWord = !_obscurePassWord;
                            });
                          },
                          icon: Icon(
                            _obscurePassWord
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    // TextFlied Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassWord,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 25,
                          horizontal: 22,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassWord =
                                  !_obscureConfirmPassWord;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassWord
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    CustomElevateButton(title: 'Đăng ký', onPressed: _handleEmailSignUp),
                    const SizedBox(height: 16),
                    // Chia 2 nút
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'HOẶC',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Button Sign In Google
                    CustomOutlinedButton(
                      title: 'Đăng nhập với Goole',
                      icon: SvgPicture.asset(
                        AppVectors.icon_google,
                        width: 20,
                        height: 20,
                      ),
                      onPressed: _handleGoogleLogin,
                    ),
                    const SizedBox(height: 20),

                    // Chuyển sang trang đăng ký
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Bạn đã có tài khoản? '),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SigninPage(),
                              ),
                            );
                          },
                          child: const Text('Đăng nhập ngay'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
