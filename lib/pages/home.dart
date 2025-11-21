// lib/pages/home.dart
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:buzzify/blocs/data/data_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/pages/albums.dart';
import 'package:buzzify/pages/library.dart';
import 'package:buzzify/pages/play_song.dart';
import 'package:buzzify/pages/playlist.dart';
import 'package:buzzify/pages/search.dart';
import 'package:buzzify/pages/artist.dart';
import 'package:buzzify/pages/profile_page.dart'; // Import ProfilePage
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // <-- XÓA
import 'package:buzzify/common/formatters.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import 'package:buzzify/widgets/music_visualizer.dart'; 
import 'package:buzzify/blocs/auth/auth_bloc.dart'; // <-- THÊM
import 'package:buzzify/models/user.dart'; // <-- THÊM
import 'package:buzzify/controllers/auth_controller.dart'; // Sửa import
import 'package:buzzify/widgets/authenticated_avatar.dart'; // <-- THÊM
import 'package:buzzify/widgets/song_options_modal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // 0: Home, 1: Search, 2: Library
  int _bottomNavIndex = 0; // 0, 1, 2, 3 (3 = Tạo)
  
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // 0: Trang chủ
    GlobalKey<NavigatorState>(), // 1: Tìm kiếm
    GlobalKey<NavigatorState>(), // 2: Thư viện
  ];

  bool _showAppBar = true;
  Color _miniPlayerColor = AppColors.darkGrey;
  String? _processedSongId;
  bool _isCreateDialogOpen = false;

  Future<void> _updateMiniPlayerColor(String? coverUrl) async {
    if (coverUrl == null || !mounted) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(coverUrl),
      );
      if (mounted) {
        setState(
          () => _miniPlayerColor =
              palette.mutedColor?.color ?? AppColors.darkBackground,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _miniPlayerColor = AppColors.darkGrey);
    }
  }

  // User? currentUser; // <-- XÓA (Sẽ lấy từ BLoC)

  @override
  void initState() {
    super.initState();
    // currentUser = Supabase.instance.client.auth.currentUser; // <-- XÓA
  }

  void _showCreateDialog(BuildContext context) {
    setState(() {
       _isCreateDialogOpen = true;
       _bottomNavIndex = 3; 
    });

    showModalBottomSheet(
      context: context,
      useRootNavigator: false, 
      backgroundColor: AppColors.darkGrey, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      builder: (BuildContext modalContext) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white, size: 30),
                ),
                title: const Text('Danh sách phát', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Tạo danh sách phát gồm các bài hát', style: TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(modalContext);
                  print("Tạo Playlist Mới");
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(25.0), 
                  ),
                  child: const Icon(Icons.people, color: Colors.white, size: 30),
                ),
                title: const Text('Jam', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Cùng nghe nhạc ở bất cứ đâu', style: TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(modalContext);
                  print("Bắt đầu Jam");
                },
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        _isCreateDialogOpen = false;
        _bottomNavIndex = _selectedIndex; 
      });
    });
  }

  // --- SỬA HÀM NÀY (Thêm User) ---
  void _showRightSideMenu(BuildContext context, User? user) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.darkGrey,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Dùng AuthenticatedAvatar để hiển thị
                        AuthenticatedAvatar(
                          user: user, 
                          radius: 30, 
                          fontSize: 30, 
                          iconSize: 30
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            user?.hoTen ?? 'Không có tên',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: Colors.grey),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person),
                      title: const Text('Xem hồ sơ'),
                      onTap: () {
                         Navigator.pop(context); // Đóng menu
                         Navigator.of(context).push(
                           MaterialPageRoute(builder: (context) => const ProfilePage())
                         );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.settings),
                      title: const Text('Cài đặt'),
                      onTap: () {},
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout),
                      title: const Text('Đăng xuất'),
                      onTap: () {
                        Navigator.pop(context);
                        AuthController.signOut(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        );
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
  // --- KẾT THÚC SỬA ---

  // --- SỬA HÀM NÀY (Thêm User) ---
  List<Widget> _buildAppBarActions(User? user) {
    if (_selectedIndex == 2) { // "Thư viện"
      return [
        IconButton(
          onPressed: () { /* TODO: Logic tìm kiếm thư viện */ },
          icon: const Icon(Icons.search, size: 28),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            onTap: () => _showRightSideMenu(context, user), // <-- Pass user
            child: AuthenticatedAvatar(user: user, radius: 16, iconSize: 18),
          ),
        ),
      ];
    } 
    
    // Mặc định (Trang chủ, Tìm kiếm)
    return [
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.notifications_none),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: GestureDetector(
          onTap: () => _showRightSideMenu(context, user), // <-- Pass user
          child: AuthenticatedAvatar(user: user, radius: 16, iconSize: 18),
        ),
      ),
    ];
  }
  // --- KẾT THÚC SỬA ---

  @override
  Widget build(BuildContext context) {
    // --- SỬA LỖI TẠI ĐÂY ---
    // 1. Dùng .watch() để lắng nghe thay đổi
    final authState = context.watch<AuthBloc>().state;
    final User? user = authState.user; // Lấy user mới nhất

    final audioState = context.watch<AudioPlayerBloc>().state;
    // --- KẾT THÚC SỬA ---
    
    final pageTitles = ['Trang chủ', 'Tìm kiếm', 'Thư viện'];
    final song = audioState.currentSong;

    if (song != null && song['id'] != _processedSongId) {
      _processedSongId = song['id'];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateMiniPlayerColor(song['cover_url']); 
      });
    }
    
    void onTabTapped(int index) {
      if (index == 3) { 
        _showCreateDialog(context); 
      } else {
        setState(() {
          _selectedIndex = index; 
          _bottomNavIndex = index; 
        });
      }
    }

    return Scaffold(
      appBar: _showAppBar
          ? AppBar(
              title: Text(
                pageTitles[_selectedIndex], 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              backgroundColor: AppColors.darkBackground,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: _buildAppBarActions(user), // <-- 2. Pass user
            )
          : null, 
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: audioState.currentSong != null ? 70 : 0,
            ),
            child: IndexedStack(
              index: _selectedIndex, 
              children: <Widget>[
                _buildTabNavigator(
                  _navigatorKeys[0], // Key 0
                  HomeTabContent(
                    onNavigationChanged: (showAppBar) {
                      setState(() => _showAppBar = showAppBar);
                    },
                  ),
                ),
                _buildTabNavigator(
                  _navigatorKeys[1], // Key 1
                  SearchPage( 
                    onNavigationChanged: (showAppBar) {
                      setState(() => _showAppBar = showAppBar);
                    },
                  ),
                ),
                _buildTabNavigator(
                  _navigatorKeys[2], // Key 2
                  LibraryPage(
                    onNavigationChanged: (showAppBar) {
                      setState(() => _showAppBar = showAppBar);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (audioState.currentSong != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildMiniPlayer(context, audioState),
            ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex, 
        onTap: onTabTapped, 
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: AppColors.darkBackground,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Trang chủ',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Thư viện',
          ),
          BottomNavigationBarItem(
            icon: Icon(_isCreateDialogOpen ? Icons.close : Icons.add), 
            label: 'Tạo'
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigator(GlobalKey<NavigatorState> key, Widget page) =>
      Navigator(
        key: key,
        onGenerateRoute: (s) => MaterialPageRoute(builder: (c) => page),
      );

  Widget _buildMiniPlayer(BuildContext context, AudioPlayerState audioState) {
    final song = audioState.currentSong;
    if (song == null) return const SizedBox.shrink();
    
    final imageUrl = song['cover_url'] ?? ''; 
    // --- SỬA LỖI: Ép kiểu ID về String để so sánh chính xác ---
    final songId = song['id'].toString(); 

    return GestureDetector(
      onTap: () => _showPlayerPage(context),
      child: Container(
        height: 65,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 65,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _miniPlayerColor.withValues(alpha: 0.5),
                border: Border.all(
                  color: _miniPlayerColor.withValues(alpha: 0.8),
                  width: 0.9,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl, 
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[850]),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song['title'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          buildArtistString(song),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  
                  // --- NÚT TIM (LIKE) ĐÃ SỬA ---
                  BlocBuilder<DataBloc, DataState>(
                    builder: (context, dataState) {
                      bool isLiked = false;
                      if (dataState is DataLoaded) {
                        // So sánh ID String với danh sách String
                        isLiked = dataState.likedSongIds.contains(songId);
                      }
                      return IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          // Đổi màu rõ rệt: Xanh (Primary) hoặc Trắng mờ
                          color: isLiked ? AppColors.primary : Colors.white70, 
                        ),
                        onPressed: () {
                          context.read<DataBloc>().add(ToggleLikeSong(songId));
                        },
                      );
                    },
                  ),
                  // -----------------------------

                  IconButton(
                    icon: Icon(
                      audioState.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 32,
                    ),
                    onPressed: () {
                      if (audioState.isPlaying) {
                        context.read<AudioPlayerBloc>().add(PauseRequested());
                      } else {
                        context.read<AudioPlayerBloc>().add(PlayRequested());
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPlayerPage(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlaySongPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

// --- NỘI DUNG TAB TRANG CHỦ ---
class HomeTabContent extends StatelessWidget {
  final Function(bool)? onNavigationChanged;

  const HomeTabContent({super.key, this.onNavigationChanged});

  // void _showSongOptionsModal(BuildContext context, Map<String, dynamic> song) {
  //   final imageUrl = song['cover_url']; // SỬA: Dùng 'cover_url'

  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: AppColors.darkGrey,
  //     useRootNavigator: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (modalContext) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setModalState) {
  //           bool isLiked = song['isLiked'] ?? false;
  //           return SingleChildScrollView(
  //             child: Padding(
  //               padding: const EdgeInsets.symmetric(vertical: 16.0),
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Container(
  //                     height: 5,
  //                     width: 40,
  //                     margin: const EdgeInsets.only(bottom: 16.0),
  //                     decoration: BoxDecoration(
  //                       color: Colors.grey,
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                   ),
  //                   ListTile(
  //                     leading: ClipRRect(
  //                       borderRadius: BorderRadius.circular(4),
  //                       child: CachedNetworkImage(
  //                         imageUrl: imageUrl ?? '', // SỬA
  //                         width: 50,
  //                         height: 50,
  //                         fit: BoxFit.cover,
  //                         placeholder: (context, url) =>
  //                             Container(color: Colors.grey[850]),
  //                         errorWidget: (context, url, error) =>
  //                             const Icon(Icons.error),
  //                       ),
  //                     ),
  //                     title: Text(
  //                       song['title'] ?? '',
  //                       maxLines: 1,
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                     subtitle: Text(buildArtistString(song)),
  //                   ),
  //                   const Divider(),
  //                   // (Các ListTile còn lại giữ nguyên)
  //                    ListTile(
  //                     leading: Icon(
  //                       isLiked ? Icons.favorite : Icons.favorite_border,
  //                       color: isLiked ? Colors.greenAccent : null,
  //                     ),
  //                     title: Text(isLiked ? 'Đã thích' : 'Thích'),
  //                     onTap: () {
  //                       setModalState(() {
  //                         isLiked = !isLiked;
  //                       });
  //                     },
  //                   ),
  //                   ListTile(
  //                     leading: const Icon(Icons.album),
  //                     title: const Text('Xem album'),
  //                     onTap: () {},
  //                   ),
  //                   ListTile(
  //                     leading: const Icon(Icons.person),
  //                     title: const Text('Xem nghệ sĩ'),
  //                     onTap: () {},
  //                   ),
  //                   ListTile(
  //                     leading: const Icon(Icons.playlist_add),
  //                     title: const Text('Thêm vào playlist'),
  //                     onTap: () {},
  //                   ),
  //                   ListTile(
  //                     leading: const Icon(Icons.queue_music),
  //                     title: const Text('Thêm vào danh sách phát'),
  //                     onTap: () {},
  //                   ),
  //                   ListTile(
  //                     leading: const Icon(Icons.share),
  //                     title: const Text('Chia sẻ'),
  //                     onTap: () {},
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: BlocBuilder<DataBloc, DataState>(
        builder: (context, dataState) {
          if (dataState is DataLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (dataState is DataLoaded) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  const Padding(
                    padding: EdgeInsets.only(left: 20.0, top: 16),
                    child: Text('Playlist theo chủ đề', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 230,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: dataState.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = dataState.playlists[index];
                        final imageUrl = playlist['cover_url']; // SỬA
                        return GestureDetector(
                          onTap: () {
                            onNavigationChanged?.call(false);
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => PlaylistPage(playlist: playlist),
                                  ),
                                )
                                .then((_) {
                                  onNavigationChanged?.call(true);
                                });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: 'playlist-cover-${playlist['id']}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl ?? '', // SỬA
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: Colors.grey[850]),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    playlist['title'],
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.only(left: 20.0, top: 16),
                    child: Text('Albums', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 230,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: dataState.albums.length,
                      itemBuilder: (context, index) {
                        final album = dataState.albums[index];
                        final imageUrl = album['cover_url']; // SỬA
                        return GestureDetector(
                          onTap: () {
                            onNavigationChanged?.call(false);
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => AlbumPage(album: album),
                                  ),
                                )
                                .then((_) {
                                  onNavigationChanged?.call(true);
                                });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: 'album-cover-${album['id']}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl ?? '', // SỬA
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: Colors.grey[850]),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    album['title'],
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    album['artists']?['name'] ?? 'Không rõ',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.only(left: 20.0, top: 10),
                    child: Text('Bài hát', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                    builder: (context, audioState) {
                      final currentSong = audioState.currentSong;
                      
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        itemCount: dataState.songs.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final song = dataState.songs[index];
                          final imageUrl = song['cover_url']; // SỬA
                          final String thisContextId = 'all-songs';
                          
                          final bool isPlayingThisSong =
                              currentSong != null &&
                              currentSong['id'] == song['id'] &&
                              audioState.contextId == thisContextId;

                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl ?? '', // SỬA
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey[850]),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            ),
                            title: Row(
                              children: [
                                if (isPlayingThisSong)
                                  MusicVisualizer(isPlaying: audioState.isPlaying),
                                if (isPlayingThisSong)
                                  const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    song['title'] ?? 'Không có tiêu đề',
                                    style: TextStyle(
                                      color: isPlayingThisSong ? AppColors.primary : null,
                                      fontWeight: isPlayingThisSong ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(buildArtistString(song)),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => showSongOptionsModal(context, song, onNavigationChanged: onNavigationChanged),
                            ),
                            onTap: () => context.read<AudioPlayerBloc>().add(
                              StartPlaying(
                                playlist: dataState.songs, 
                                index: index,
                                playlistTitle: "Tất cả bài hát",
                                contextId: thisContextId, 
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          }
          if (dataState is DataError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${dataState.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}