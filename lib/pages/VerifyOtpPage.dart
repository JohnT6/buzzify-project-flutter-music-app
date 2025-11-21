// lib/pages/VerifyOtpPage.dart
import 'dart:async'; // <-- THÊM: Import Timer
import 'package:flutter/material.dart';
import 'package:buzzify/controllers/auth_controller.dart'; // Sửa import
import 'package:buzzify/common/app_colors.dart'; 
import 'package:buzzify/pages/SignUpOrSignIn.dart'; 
import 'package:buzzify/pages/signin.dart'; 

class VerifyOtpPage extends StatefulWidget {
  final String email;
  const VerifyOtpPage({super.key, required this.email});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // --- THÊM LOGIC COOLDOWN ---
  Timer? _timer;
  int _cooldownSeconds = 60; // Thời gian chờ 60 giây
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hủy timer khi rời trang
    _otpController.dispose();
    super.dispose();
  }

  // Bắt đầu đếm ngược
  void _startCooldownTimer() {
    setState(() => _canResend = false);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        if (mounted) {
          setState(() => _cooldownSeconds--);
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() => _canResend = true);
        }
      }
    });
  }

  // Xử lý gửi lại
  Future<void> _resendOtp() async {
    if (!_canResend) return; // Nếu đang đếm ngược thì không làm gì

    setState(() {
      _cooldownSeconds = 60; // Reset lại 60 giây
    });
    _startCooldownTimer(); // Bắt đầu đếm ngược lại

    // Gọi AuthController
    await AuthController.resendOtp(
      context: context,
      email: widget.email,
    );
  }
  // --- KẾT THÚC LOGIC COOLDOWN ---

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);

    await AuthController.verifyOtp(
      context: context,
      email: widget.email,
      otp: _otpController.text.trim(),
    );

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: const CustomAppBar(),
      body: isLoading
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
                      "Xác thực tài khoản",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nhập mã OTP (6 số) đã được gửi đến email:\n${widget.email}', 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 40),

                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, letterSpacing: 8),
                      decoration: InputDecoration(
                        labelText: 'Mã OTP',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 25,
                          horizontal: 22,
                        ),
                      ),
                      maxLength: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập OTP';
                        }
                        if (value.length != 6) {
                          return 'OTP phải có 6 chữ số';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    CustomElevateButton(
                      title: 'Xác nhận',
                      onPressed: isLoading ? () {} : _verifyOtp,
                    ),
                    
                    const SizedBox(height: 16),
                    // --- NÚT GỬI LẠI MÃ ---
                    TextButton(
                      // Nếu _canResend = false (đang đếm ngược), nút sẽ bị mờ
                      onPressed: _canResend ? _resendOtp : null, 
                      child: Text(
                        _canResend
                            ? 'Gửi lại mã'
                            // Hiển thị đếm ngược
                            : 'Gửi lại mã sau (${_cooldownSeconds}s)',
                        style: TextStyle(
                          color: _canResend ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ),
                    // --- KẾT THÚC NÚT GỬI LẠI ---
                  ],
                ),
              ),
            ),
    );
  }
}