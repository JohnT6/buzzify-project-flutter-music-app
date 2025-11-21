// lib/pages/library.dart
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:buzzify/blocs/auth/auth_bloc.dart'; // Import AuthBloc
import 'package:buzzify/blocs/data/data_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/services/api_playlist_service.dart'; // Import Service
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:buzzify/pages/albums.dart';
import 'package:buzzify/pages/playlist.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buzzify/pages/artist.dart'; 

class LibraryPage extends StatefulWidget {
  final Function(bool)? onNavigationChanged;
  const LibraryPage({super.key, this.onNavigationChanged});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String _selectedFilter = 'Tất cả';
  bool _isGridView = false; 

  final List<String> _filters = ['Tất cả', 'Playlist', 'Album', 'Nghệ sĩ'];

  // Biến lưu trữ playlist người dùng (Liked Songs + User Created)
  List<Map<String, dynamic>> _userPlaylists = [];
  bool _isLoadingUserPlaylists = true;

  @override
  void initState() {
    super.initState();
    _fetchUserPlaylists();
  }

  // Hàm lấy playlist của người dùng
  Future<void> _fetchUserPlaylists() async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) {
      setState(() => _isLoadingUserPlaylists = false);
      return;
    }

    try {
      final service = context.read<ApiPlaylistService>();
      
      // Gọi song song: Lấy Liked Songs + Playlist tự tạo
      final results = await Future.wait([
        service.getLikedSongsPlaylist(userId),      // [0] Liked Songs
        service.getUserCreatedPlaylists(userId),    // [1] User Created
      ]);

      // Kết quả Liked Songs trả về Map (chi tiết), ta cần wrap vào List
      // Hoặc nếu API trả về object playlist, ta add vào list
      final likedPlaylist = results[0] as Map<String, dynamic>; // API getLikedSongsPlaylist trả về Map
      final createdPlaylists = results[1] as List<Map<String, dynamic>>; // API getUserCreatedPlaylists trả về List

      if (mounted) {
        setState(() {
          // Gộp vào danh sách chung. Đưa Liked Songs lên đầu.
          _userPlaylists = [
            {...likedPlaylist, '__type': 'playlist'}, 
            ...createdPlaylists.map((p) => {...p, '__type': 'playlist'}).toList()
          ];
          _isLoadingUserPlaylists = false;
        });
      }
    } catch (e) {
      print("Lỗi tải playlist thư viện: $e");
      if (mounted) setState(() => _isLoadingUserPlaylists = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Column(
        children: [
          _buildFilterChips(),
          _buildListControls(),
          Expanded(child: _buildLibraryList()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              labelStyle: TextStyle(
                color: Colors.white, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                }
              },
              backgroundColor: AppColors.darkGrey,
              selectedColor: AppColors.primary, 
              showCheckmark: false,
              shape: const StadiumBorder(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.sort, color: Colors.white), 
            label: const Text('Gần đây', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view_outlined, 
              color: Colors.white
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryList() {
    return BlocBuilder<DataBloc, DataState>(
      builder: (context, state) {
        if (state is DataLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DataLoaded) {
          // Lấy dữ liệu tổng hợp (Global + User)
          final itemsToShow = _getFilteredData(state);

          if (itemsToShow.isEmpty && !_isLoadingUserPlaylists) {
            return const Center(child: Text('Thư viện trống.', style: TextStyle(color: Colors.grey)));
          }

          if (_isGridView) {
            return _buildGridView(itemsToShow); 
          } else {
            return _buildListView(itemsToShow); 
          }
        }
        if (state is DataError) {
          return Center(child: Text('Lỗi: ${state.message}'));
        }
        return const SizedBox.shrink();
      },
    );
  }
  
  Widget _buildListView(List<Map<String, dynamic>> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final itemType = item['__type'] ?? 'unknown';
        final isArtist = itemType == 'artist';
        
        // Kiểm tra ghim (Liked Songs)
        final bool isPinned = item['loai_playlist'] == 'liked_songs' || item['title'] == 'Bài hát đã thích';
        
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(isArtist ? 25.0 : 4.0),
            child: CachedNetworkImage(
              imageUrl: item['cover_url'] ?? item['avatar_url'] ?? '', 
              width: 50, height: 50, 
              fit: BoxFit.cover,
              errorWidget: (c, u, e) => Container(
                width: 50, height: 50, 
                color: AppColors.darkGrey,
                child: Icon(
                  isPinned ? Icons.favorite :
                  (itemType == 'album' ? Icons.album : 
                  (itemType == 'playlist' ? Icons.queue_music : 
                  (itemType == 'artist' ? Icons.person : Icons.music_note)))
                ),
              ),
            ),
          ),
          title: Text(
            item['title'] ?? item['name'] ?? 'Không có tiêu đề',
            style: TextStyle(
              color: isPinned ? AppColors.primary : Colors.white,
              fontWeight: isPinned ? FontWeight.bold : FontWeight.normal
            ),
          ),
          subtitle: Row(
            children: [
              if (isPinned) ...[
                Transform.rotate(
                  angle: 0.7, 
                  child: const Icon(Icons.push_pin, size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  item['subtitle_text'] ?? 'Không rõ',
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          onTap: () => _onItemTapped(item),
        );
      },
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        crossAxisSpacing: 16.0, 
        mainAxisSpacing: 16.0, 
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final itemType = item['__type'] ?? 'unknown';
        final isArtist = itemType == 'artist';
        final bool isPinned = item['loai_playlist'] == 'liked_songs' || item['title'] == 'Bài hát đã thích';
        
        return GestureDetector(
          onTap: () => _onItemTapped(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isArtist ? 40.0 : 8.0),
                  child: CachedNetworkImage(
                    imageUrl: item['cover_url'] ?? item['avatar_url'] ?? '',
                    fit: BoxFit.cover, 
                    width: double.infinity,
                    errorWidget: (c, u, e) => Container(
                      color: AppColors.darkGrey,
                      child: Icon(
                        isPinned ? Icons.favorite :
                        (itemType == 'album' ? Icons.album : 
                        (itemType == 'playlist' ? Icons.queue_music : 
                        (itemType == 'artist' ? Icons.person : Icons.music_note)))
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'] ?? item['name'] ?? '', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPinned ? AppColors.primary : Colors.white,
                ), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
              Row(
                children: [
                  if (isPinned) ...[
                    Transform.rotate(
                      angle: 0.7, 
                      child: const Icon(Icons.push_pin, size: 12, color: AppColors.primary),
                    ),
                    const SizedBox(width: 2),
                  ],
                  Expanded(
                    child: Text(
                      item['subtitle_text'] ?? 'Không rõ', 
                      style: const TextStyle(color: Colors.grey, fontSize: 12), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- HÀM QUAN TRỌNG: Trộn dữ liệu Global + User ---
  List<Map<String, dynamic>> _getFilteredData(DataLoaded state) {
    switch (_selectedFilter) {
      case 'Tất cả':
        // 1. Lấy playlist người dùng (đã bao gồm Liked Songs)
        final userItems = _userPlaylists.map((p) => {
          ...p,
          'subtitle_text': p['loai_playlist'] == 'liked_songs' ? 'Playlist • Đã ghim' : 'Playlist • Của bạn'
        }).toList();

        // 2. Lấy Album (từ DataBloc)
        final albums = state.albums.map((a) => {
          ...a,
          '__type': 'album',
          'subtitle_text': 'Album • ${a['artists']?['name'] ?? 'Không rõ'}'
        }).toList();
        
        // 3. Lấy Nghệ sĩ (từ DataBloc)
        final artists = state.artists.map((art) => {
          ...art,
          '__type': 'artist',
          'subtitle_text': 'Nghệ sĩ'
        }).toList();

        // Trộn tất cả
        return [...userItems, ...albums, ...artists];

      case 'Playlist': 
        return _userPlaylists.map((p) => {
          ...p,
          'subtitle_text': p['loai_playlist'] == 'liked_songs' ? 'Playlist • Đã ghim' : 'Playlist • Của bạn'
        }).toList();
        
      case 'Album':
        return state.albums.map((a) => {
          ...a,
          '__type': 'album',
          'subtitle_text': 'Album • ${a['artists']?['name'] ?? 'Không rõ'}'
        }).toList();

      case 'Nghệ sĩ':
        return state.artists.map((art) => {
          ...art,
          '__type': 'artist',
          'subtitle_text': 'Nghệ sĩ'
        }).toList();
        
      default:
        return [];
    }
  }

  void _onItemTapped(Map<String, dynamic> item) {
     widget.onNavigationChanged?.call(false);
     Widget destinationPage;

     switch (item['__type']) {
        case 'album':
          destinationPage = AlbumPage(album: item);
          break;
        case 'playlist':
          destinationPage = PlaylistPage(playlist: item);
          break;
        case 'artist':
          destinationPage = ArtistPage(artist: item);
          break;
        default:
          widget.onNavigationChanged?.call(true); 
          return; 
     }
     
     Navigator.of(context).push(
       MaterialPageRoute(builder: (_) => destinationPage),
     ).then((_) {
       widget.onNavigationChanged?.call(true);
     });
  }
}