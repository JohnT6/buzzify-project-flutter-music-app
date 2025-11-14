// lib/pages/home.dart
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:buzzify/blocs/data/data_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/pages/albums.dart';
import 'package:buzzify/pages/library.dart';
import 'package:buzzify/pages/play_song.dart';
import 'package:buzzify/pages/playlist.dart';
import 'package:buzzify/pages/search.dart';
import 'package:buzzify/supabase/auth_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buzzify/common/formatters.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import 'package:buzzify/widgets/music_visualizer.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  // SỬA LỖI 1: Chỉ cần 3 GlobalKeys cho 3 tab
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // 0: Trang chủ
    GlobalKey<NavigatorState>(), // 1: Tìm kiếm
    GlobalKey<NavigatorState>(), // 2: Thư viện
  ];
  // --- KẾT THÚC SỬA 1 ---

  bool _showAppBar = true;
  Color _miniPlayerColor = AppColors.darkGrey;
  String? _processedSongId;
  bool _isCreateDialogOpen = false;

  Future<void> _updateMiniPlayerColor(String? coverUrl) async {
    if (coverUrl == null || !mounted) return;
    final publicUrl = coverUrl;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(publicUrl),
      );
      if (mounted) {
        setState(
          () => _miniPlayerColor =
              palette.vibrantColor?.color ?? AppColors.darkGrey,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _miniPlayerColor = AppColors.darkGrey);
    }
  }

  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = Supabase.instance.client.auth.currentUser;
  }

  // Hàm tạo Dialog "Tạo" (Đã đúng)
  void _showCreateDialog(BuildContext context) {
    setState(() => _isCreateDialogOpen = true);

    showModalBottomSheet(
      context: context,
      // Hiển thị dialog BÊN TRÊN BottomNav
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
              // 1. Tạo danh sách phát
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
              // 2. Jam
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
      setState(() => _isCreateDialogOpen = false);
    });
  }

  // (Hàm _showRightSideMenu giữ nguyên)
  void _showRightSideMenu(BuildContext context) {
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
                        CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              currentUser?.userMetadata?['avatar_url'] != null
                              ? NetworkImage(
                                  currentUser!.userMetadata!['avatar_url'],
                                )
                              : null,
                          child:
                              currentUser?.userMetadata?['avatar_url'] == null
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            currentUser?.userMetadata?['full_name'] ??
                                'Không có tên',
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
                      onTap: () {},
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

  // Hàm build actions cho AppBar (Đã đúng)
  List<Widget> _buildAppBarActions() {
    if (_selectedIndex == 2) { // 2 = Tab "Thư viện"
      return [
        IconButton(
          onPressed: () { /* TODO: Logic tìm kiếm thư viện */ },
          icon: const Icon(Icons.search, size: 28),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            onTap: () => _showRightSideMenu(context),
            child: CircleAvatar(
              radius: 16,
              backgroundImage:
                  currentUser?.userMetadata?['avatar_url'] != null
                  ? NetworkImage(
                      currentUser!.userMetadata!['avatar_url'],
                    )
                  : null,
              child: currentUser?.userMetadata?['avatar_url'] == null
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
          ),
        ),
      ];
    } 
    
    // Mặc định (cho Trang chủ, Tìm kiếm)
    return [
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.notifications_none),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: GestureDetector(
          onTap: () => _showRightSideMenu(context),
          child: CircleAvatar(
            radius: 16,
            backgroundImage:
                currentUser?.userMetadata?['avatar_url'] != null
                ? NetworkImage(
                    currentUser!.userMetadata!['avatar_url'],
                  )
                : null,
            child: currentUser?.userMetadata?['avatar_url'] == null
                ? const Icon(Icons.person, size: 18)
                : null,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final audioState = context.watch<AudioPlayerBloc>().state;
    // SỬA LỖI 2: Chỉ cần 3 title
    final pageTitles = ['Trang chủ', 'Tìm kiếm', 'Thư viện'];
    // --- KẾT THÚC SỬA 2 ---
    final song = audioState.currentSong;

    if (song != null && song['id'] != _processedSongId) {
      _processedSongId = song['id'];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateMiniPlayerColor(song['cover_url']);
      });
    }
    
    // SỬA LỖI 3: Logic khi nhấn Tab
    void onTabTapped(int index) {
      if (index == 3) { // 3 là index của nút "Tạo"
        _showCreateDialog(context); // Chỉ mở dialog
      } else {
        setState(() => _selectedIndex = index); // Chuyển tab
      }
    }
    // --- KẾT THÚC SỬA 3 ---

    return Scaffold(
      appBar: _showAppBar
          ? AppBar(
              title: Text(
                pageTitles[_selectedIndex], // Dùng _selectedIndex (0, 1, hoặc 2)
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              backgroundColor: AppColors.darkBackground,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: _buildAppBarActions(), // Gọi hàm build actions động
            )
          : null, 
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: audioState.currentSong != null ? 70 : 0,
            ),
            // SỬA LỖI 4: IndexedStack chỉ có 3 con
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
                // Bỏ child thứ 4 (index 3)
              ],
            ),
            // --- KẾT THÚC SỬA 4 ---
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
        currentIndex: _selectedIndex,
        onTap: onTabTapped, // Dùng hàm onTabTapped đã sửa
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
          // Thay đổi icon "Tạo" / "X"
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
    // ... (Code MiniPlayer giữ nguyên)
    final song = audioState.currentSong;
    if (song == null) return const SizedBox.shrink();
    final imageUrl = song['cover_url'] ?? '';
    final isLiked = song['isLiked'] ?? false;

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
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[850]),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song['title']!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          buildArtistString(song),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppColors.primary : Colors.white70,
                    ),
                    onPressed: () {},
                  ),
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
// (Class HomeTabContent giữ nguyên, không cần sửa)
class HomeTabContent extends StatelessWidget {
  final Function(bool)? onNavigationChanged;

  const HomeTabContent({super.key, this.onNavigationChanged});

  void _showSongOptionsModal(BuildContext context, Map<String, dynamic> song) {
    // ... (Code bên trong giữ nguyên)
    final imageUrl = song['cover_url'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkGrey,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isLiked = song['isLiked'] ?? false;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 5,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey[850]),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                      title: Text(
                        song['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(buildArtistString(song)),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.greenAccent : null,
                      ),
                      title: Text(isLiked ? 'Đã thích' : 'Thích'),
                      onTap: () {
                        setModalState(() {
                          isLiked = !isLiked;
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.album),
                      title: const Text('Xem album'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Xem nghệ sĩ'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.playlist_add),
                      title: const Text('Thêm vào playlist'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.queue_music),
                      title: const Text('Thêm vào danh sách phát'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.share),
                      title: const Text('Chia sẻ'),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
                    child: Text(
                      'Playlist theo chủ đề',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 230,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: dataState.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = dataState.playlists[index];
                        final imageUrl = playlist['cover_url'];
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
                                      imageUrl: imageUrl,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Container(color: Colors.grey[850]),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    playlist['title'],
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
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
                    child: Text(
                      'Albums',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 230,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: dataState.albums.length,
                      itemBuilder: (context, index) {
                        final album = dataState.albums[index];
                        final imageUrl = album['cover_url'];
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
                                      imageUrl: imageUrl,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Container(color: Colors.grey[850]),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    album['title'],
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    album['artists']?['name'] ?? 'Không rõ',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
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
                    child: Text(
                      'Bài hát',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                          final imageUrl = song['cover_url'];
                          
                          final String thisContextId = 'all-songs';
                          
                          final bool isPlayingThisSong =
                              currentSong != null &&
                              currentSong['id'] == song['id'] &&
                              audioState.contextId == thisContextId;

                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: Colors.grey[850]),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
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
                              onPressed: () => _showSongOptionsModal(context, song),
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