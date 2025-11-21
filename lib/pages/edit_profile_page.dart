// lib/pages/edit_profile_page.dart
import 'dart:io'; // <-- THÊM IMPORT NÀY
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buzzify/blocs/auth/auth_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buzzify/controllers/auth_controller.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:buzzify/services/api_client.dart'; 
import 'package:buzzify/services/api_constants.dart'; 

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  final ImagePicker _picker = ImagePicker();

  // --- SỬA LỖI LOGIC ---
  // 1. Biến lưu file ảnh TẠM THỜI (chưa upload)
  File? _pickedImageFile; 
  // 2. Biến đánh dấu nếu người dùng muốn XÓA ảnh
  bool _isImageRemoved = false; 
  // --- KẾT THÚC SỬA ---

  @override
  void initState() {
    super.initState();
    final currentUser = context.read<AuthBloc>().state.user;
    _nameController = TextEditingController(text: currentUser?.hoTen ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- SỬA LỖI LOGIC: HÀM LƯU MỚI ---
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    String? newAvatarUrl; // URL để gửi cho AuthController
    bool hasAvatarChanged = false; // Flag
    
    final newName = _nameController.text.trim();
    final currentName = context.read<AuthBloc>().state.user?.hoTen ?? '';
    bool hasNameChanged = newName != currentName;

    try {
      // BƯỚC 1: Xử lý ảnh (Nếu có thay đổi)
      if (_isImageRemoved) {
        newAvatarUrl = ""; // Gửi chuỗi rỗng để xóa
        hasAvatarChanged = true;
      } 
      else if (_pickedImageFile != null) {
        // Nếu có file ảnh mới, TẢI LÊN NGAY BÂY GIỜ
        final apiClient = context.read<ApiClient>(); 
        final data = await apiClient.uploadFile(
          ApiConstants.fileUpload, 
          _pickedImageFile!.path, 
          'file',
          mimeType: _pickedImageFile!.path.endsWith('.png') ? 'image/png' : 'image/jpeg',
        );
        newAvatarUrl = data['filePath']; // Lấy URL từ server
        hasAvatarChanged = true;
      }

      // BƯỚC 2: Cập nhật hồ sơ
      // Chỉ gọi API nếu có gì đó thay đổi
      if (hasNameChanged || hasAvatarChanged) {
        final success = await AuthController.updateProfile(
          context: context,
          hoTen: hasNameChanged ? newName : null, // Chỉ gửi nếu tên thay đổi
          anhDaiDien: hasAvatarChanged ? newAvatarUrl : null, // Chỉ gửi nếu ảnh thay đổi
        );

        if (mounted && success) {
          Navigator.of(context).pop(); // Quay về nếu thành công
        }
      } else {
        // Không có gì thay đổi
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // --- KẾT THÚC SỬA LỖI ---

  // Hàm này sẽ hiển thị dialog (Hình 1)
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thêm ảnh hồ sơ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),
              // Nút Tải ảnh lên
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.white70),
                title: const Text('Tải ảnh lên', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop(); 
                  _pickImage(ImageSource.gallery); // Mở thư viện
                },
              ),
              // Nút Chụp ảnh
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.white70),
                title: const Text('Chụp ảnh', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop(); 
                  _pickImage(ImageSource.camera); // Mở camera
                },
              ),
              // Nút Xóa ảnh
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Xóa ảnh hiện tại', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.of(context).pop(); 
                  _removeImage(); // Gọi hàm xóa ảnh
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- SỬA HÀM NÀY ---
  // Hàm này chỉ CHỌN ảnh, KHÔNG upload
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image == null) {
      return; // Người dùng đã hủy
    }
    
    // Cập nhật UI ngay lập tức
    setState(() {
      _pickedImageFile = File(image.path);
      _isImageRemoved = false; // Bỏ cờ xóa (nếu có)
    });
  }
  // --- KẾT THÚC SỬA ---

  // Hàm này xử lý việc xóa ảnh (tạm thời)
  Future<void> _removeImage() async {
    setState(() {
      _pickedImageFile = null; // Xóa file tạm
      _isImageRemoved = true; // Đặt cờ xóa
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Dùng watch để UI tự cập nhật khi ảnh thay đổi (khi BLoC được cập nhật)
    // HOẶC dùng _pickedImageFile để xem trước ảnh (local)
    final User? user = context.watch<AuthBloc>().state.user;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: Text(
              'Lưu',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: Stack( 
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      // Sửa: Gọi _buildAvatar(user)
                      _buildAvatar(user), 
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: _isLoading ? null : _showImageSourceSheet, // Gọi dialog
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.edit, 
                                color: Colors.black, 
                                size: 20
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Tên',
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tên không được để trống';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // --- SỬA HÀM NÀY ---
  // Widget này sẽ ưu tiên hiển thị ảnh vừa chọn (local)
  Widget _buildAvatar(User? user) {
    ImageProvider? backgroundImage;
    Widget? child;
    
    // 1. Ưu tiên ảnh vừa chọn (local)
    if (_pickedImageFile != null) {
      backgroundImage = FileImage(_pickedImageFile!);
    } 
    // 2. Nếu không, kiểm tra xem có bị xóa không
    else if (_isImageRemoved) {
      // Để rỗng (sẽ hiện chữ cái đầu)
    }
    // 3. Nếu không, dùng ảnh từ BLoC (ảnh trên server)
    else if (user?.anhDaiDien != null && user!.anhDaiDien!.isNotEmpty) {
      backgroundImage = CachedNetworkImageProvider(user.anhDaiDien!);
    }

    // Nếu không có ảnh nào (bị xóa, hoặc chưa có) -> hiển thị chữ cái đầu
    if (backgroundImage == null) {
      final String nameInitial = _nameController.text.isNotEmpty
          ? _nameController.text[0].toUpperCase()
          : (user?.hoTen?.isNotEmpty == true ? user!.hoTen![0].toUpperCase() : 'B');
      
      child = Text(
        nameInitial, 
        style: const TextStyle(fontSize: 60, color: Colors.white, fontWeight: FontWeight.bold),
      );
    }

    return CircleAvatar(
      radius: 60,
      backgroundColor: AppColors.primary,
      backgroundImage: backgroundImage,
      child: child,
    );
  }
  // --- KẾT THÚC SỬA ---
}