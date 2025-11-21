// lib/pages/profile_page.dart
import 'package:buzzify/blocs/auth/auth_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/models/user.dart';
import 'package:buzzify/pages/playlist.dart';
import 'package:buzzify/services/api_playlist_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:buzzify/pages/edit_profile_page.dart';
// Import widget Avatar mới
import 'package:buzzify/widgets/authenticated_avatar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Color _dynamicColor = AppColors.darkBackground;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _userPlaylists = [];
  String? _error;
  
  // Xóa: late User? _currentUser; (Sẽ lấy từ BLoC)

  @override
  void initState() {
    super.initState();
    // Lấy user ID MỘT LẦN để fetch data
    final userId = context.read<AuthBloc>().state.user?.id;
    _fetchProfileData(userId);
  }

  Future<void> _fetchProfileData(String? userId) async {
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = "Không tìm thấy thông tin người dùng.";
      });
      return;
    }
    
    try {
      final service = context.read<ApiPlaylistService>();
      final playlists = await service.getUserCreatedPlaylists(userId);
      
      if (!mounted) return;
      setState(() {
        _userPlaylists = playlists;
        _isLoading = false;
      });
      
      // Lấy user (có thể đã cập nhật) từ BLoC để update màu
      final currentUser = context.read<AuthBloc>().state.user;
      _updateBackgroundColor(currentUser?.anhDaiDien);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBackgroundColor(String? coverUrl) async {
    if (coverUrl == null || coverUrl.isEmpty || !mounted) {
       setState(() => _dynamicColor = AppColors.darkGrey);
       return;
    }
    
    // Nếu là link Google (public)
    if (coverUrl.startsWith('http')) {
      try {
        final palette = await PaletteGenerator.fromImageProvider(
          CachedNetworkImageProvider(coverUrl),
        );
        if (mounted) {
          setState(() => _dynamicColor = palette.dominantColor?.color ?? AppColors.darkGrey);
        }
      } catch (e) {
        setState(() => _dynamicColor = AppColors.darkGrey);
      }
    }
    // (Nếu là link API /my-avatar, việc lấy màu sẽ phức tạp hơn
    // vì cần gửi token, tạm thời bỏ qua để giữ sự đơn giản)
    else {
       setState(() => _dynamicColor = AppColors.darkGrey);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- SỬA LỖI: Lấy user mới nhất từ .watch() ---
    final User? _currentUser = context.watch<AuthBloc>().state.user;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_dynamicColor, AppColors.darkBackground],
          stops: const [0.0, 0.5], // Chuyển màu mượt
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 350.0,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      // SỬA: Dùng AuthenticatedAvatar
                      AuthenticatedAvatar(
                        user: _currentUser,
                        radius: 60,
                        fontSize: 60,
                        iconSize: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentUser?.hoTen ?? 'Người dùng Buzzify',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '0 followers • 28 following',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const EditProfilePage())
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54, width: 1.5),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            child: const Text('Sửa'),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white54),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'Playlists',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            _buildPlaylistList(),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // (Hàm _buildAvatar đã bị xóa, thay bằng AuthenticatedAvatar)

  Widget _buildPlaylistList() {
    if (_isLoading) {
      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return SliverToBoxAdapter(child: Center(child: Text('Lỗi: $_error')));
    }
    if (_userPlaylists.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Chưa có playlist nào.', style: TextStyle(color: Colors.grey))),
        )
      );
    }
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final playlist = _userPlaylists[index];
          final imageUrl = playlist['cover_url'];
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: CachedNetworkImage(
                imageUrl: imageUrl ?? '', 
                width: 50, height: 50, fit: BoxFit.cover,
                errorWidget: (c,u,e) => Container(width: 50, height: 50, color: AppColors.darkGrey, child: Icon(Icons.music_note)),
              ),
            ),
            title: Text(playlist['title'] ?? 'Không có tiêu đề'),
            subtitle: Text(
              playlist['subtitle_text'] ?? 'Playlist', 
              style: const TextStyle(color: Colors.grey)
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PlaylistPage(playlist: playlist)),
              );
            },
          );
        },
        childCount: _userPlaylists.length,
      ),
    );
  }
}