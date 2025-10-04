import 'package:buzzify/common/app_vectors.dart';
import 'package:buzzify/pages/signup.dart';
import 'package:buzzify/supabase/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:buzzify/pages/SignUpOrSignIn.dart';
import 'package:flutter_svg/svg.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassWord = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    print('Đã nhấn đăng nhập');
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await AuthController.signInWithEmail(
      context: context,
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });

    await AuthController.signInWithGoogle(context);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    const SizedBox(height: 30),
                    // Title
                    Text(
                      "Đăng nhập",
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
                    ),
                    const SizedBox(height: 25),
                    CustomElevateButton(
                      title: 'Đăng nhập',
                      onPressed: _handleEmailLogin,
                    ),
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
                    const SizedBox(height: 75),

                    // Chuyển sang trang đăng ký
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Bạn chưa có tài khoản? '),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SignupPage(),
                              ),
                            );
                          },
                          child: const Text('Đăng ký ngay'),
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

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final bool showBackButton;

  const CustomAppBar({super.key, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: SvgPicture.asset(AppVectors.logo, width: 140, height: 140),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      leading: showBackButton
          ? IconButton(
              onPressed: onBack ?? () => Navigator.pop(context),
              icon: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
