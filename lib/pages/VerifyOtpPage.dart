// import 'package:flutter/material.dart';
// import 'package:buzzify/pages/home.dart';
// import 'package:buzzify/supabase/auth_service.dart';

// class VerifyOtpPage extends StatefulWidget {
//   final String email;
//   const VerifyOtpPage({super.key, required this.email});

//   @override
//   State<VerifyOtpPage> createState() => _VerifyOtpPageState();
// }

// class _VerifyOtpPageState extends State<VerifyOtpPage> {
//   final TextEditingController _otpController = TextEditingController();
//   bool isLoading = false;

//   Future<void> _verifyOtp() async {
//     setState(() => isLoading = true);

//     final isValid = await AuthService.verifyOtp(widget.email, _otpController.text);
//     if (!context.mounted) return;

//     if (isValid) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Xác thực thành công!'), backgroundColor: Colors.green),
//       );
//       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Sai mã OTP'), backgroundColor: Colors.red),
//       );
//     }

//     setState(() => isLoading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Xác thực email')),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             const Text('Nhập mã OTP đã gửi đến email của bạn'),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _otpController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: 'Mã OTP',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: isLoading ? null : _verifyOtp,
//               child: isLoading
//                   ? const CircularProgressIndicator()
//                   : const Text('Xác nhận'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
