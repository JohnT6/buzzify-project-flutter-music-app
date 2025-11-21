// lib/widgets/authenticated_avatar.dart
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/models/user.dart';
import 'package:buzzify/services/api_auth_service.dart';
import 'package:buzzify/services/api_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Widget này tự động xử lý việc hiển thị avatar
// (Cả link Google và link upload)
class AuthenticatedAvatar extends StatefulWidget {
  final User? user;
  final double radius;
  final double iconSize;
  final double fontSize;

  const AuthenticatedAvatar({
    super.key,
    required this.user,
    this.radius = 16.0,
    this.iconSize = 18.0,
    this.fontSize = 24.0,
  });

  @override
  State<AuthenticatedAvatar> createState() => _AuthenticatedAvatarState();
}

class _AuthenticatedAvatarState extends State<AuthenticatedAvatar> {
  // Biến để lưu trữ token
  Future<Map<String, String>>? _imageHeaders;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  // Khi widget được cập nhật (ví dụ: user.anhDaiDien thay đổi)
  @override
  void didUpdateWidget(AuthenticatedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user?.anhDaiDien != oldWidget.user?.anhDaiDien) {
      _loadImage(); // Tải lại ảnh
    }
  }

  void _loadImage() {
    final avatarUrl = widget.user?.anhDaiDien;

    // Nếu là link Google (đã public), không cần token
    if (avatarUrl != null && avatarUrl.startsWith('http')) {
      setState(() {
        _imageHeaders = Future.value({}); // Headers rỗng
      });
    } 
    // Nếu là link upload (cần bảo mật) hoặc không có ảnh
    else {
      // Lấy token
      setState(() {
        _imageHeaders = _getAuthHeaders();
      });
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await context.read<ApiAuthService>().getToken();
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  // Hàm build avatar
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _imageHeaders, // Chờ token
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          // Trạng thái chờ
          return CircleAvatar(radius: widget.radius, backgroundColor: AppColors.darkGrey);
        }

        final headers = snapshot.data!;
        final avatarUrl = widget.user?.anhDaiDien;

        ImageProvider? backgroundImage;
        Widget? child;

        // 1. Nếu là link Google
        if (avatarUrl != null && avatarUrl.startsWith('http')) {
          backgroundImage = CachedNetworkImageProvider(avatarUrl, headers: headers);
        }
        // 2. Nếu là link upload (hoặc link rỗng/null)
        else if (avatarUrl != null && avatarUrl.isNotEmpty) {
          // Gọi API /api/auth/my-avatar (đã bao gồm host)
          final secureUrl = ApiConstants.baseUrl + ApiConstants.authMyAvatar;
          backgroundImage = CachedNetworkImageProvider(secureUrl, headers: headers);
        }
        
        // 3. Nếu không có ảnh (hoặc link rỗng) -> Hiển thị chữ cái đầu
        if (backgroundImage == null) {
           final String nameInitial = widget.user?.hoTen?.isNotEmpty == true
              ? widget.user!.hoTen![0].toUpperCase()
              : 'B';
          child = Text(
            nameInitial, 
            style: TextStyle(fontSize: widget.fontSize, color: Colors.white, fontWeight: FontWeight.bold),
          );
        }

        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: AppColors.primary,
          backgroundImage: backgroundImage,
          onBackgroundImageError: backgroundImage != null 
              ? (e, stack) { print("Lỗi CachedNetworkImage: $e"); } 
              : null,
          child: child,
        );
      },
    );
  }
}