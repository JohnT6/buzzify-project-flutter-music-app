// lib/pages/library.dart
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:buzzify/blocs/data/data_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:buzzify/pages/albums.dart';
import 'package:buzzify/pages/playlist.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buzzify/pages/artist.dart'; 

class LibraryPage extends StatefulWidget {
  // --- THÊM HÀM CALLBACK ---
  final Function(bool)? onNavigationChanged;
  const LibraryPage({super.key, this.onNavigationChanged});
  // --- KẾT THÚC THÊM ---

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String _selectedFilter = 'Tất cả';
  bool _isGridView = false; 

  final List<String> _filters = ['Tất cả', 'Playlist', 'Album', 'Nghệ sĩ'];

  // --- HÀM BUILD GIAO DIỆN ---

  @override
  Widget build(BuildContext context) {
    // --- XÓA APPBAR ---
    // AppBar sẽ được cung cấp bởi HomePage
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

  // Widget cho các Chip lọc
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

  // Widget cho hàng "Gần đây" và nút "Grid/List"
  Widget _buildListControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {
              // TODO: Logic sắp xếp
            },
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

  // --- HIỂN THỊ DANH SÁCH THƯ VIỆN ---
  Widget _buildLibraryList() {
    return BlocBuilder<DataBloc, DataState>(
      builder: (context, state) {
        if (state is DataLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DataLoaded) {
          final itemsToShow = _getFilteredData(state);

          if (itemsToShow.isEmpty) {
            return Center(child: Text('Thư viện của bạn cho mục này đang trống.', style: TextStyle(color: Colors.grey)));
          }

          if (_isGridView) {
            return _buildGridView(itemsToShow); // Hiển thị Grid
          } else {
            return _buildListView(itemsToShow); // Hiển thị List
          }
        }
        if (state is DataError) {
          return Center(child: Text('Lỗi tải dữ liệu: ${state.message}'));
        }
        return const SizedBox.shrink();
      },
    );
  }
  
  // Hàm render danh sách (ListView)
  Widget _buildListView(List<Map<String, dynamic>> items) {
    if (_selectedFilter == 'Tất cả' || _selectedFilter == 'Playlist') {
      if (items.isEmpty || items.first['__type'] != 'liked_songs') {
          items.insert(0, {
          '__type': 'liked_songs',
          'id': 'liked-songs-placeholder',
          'title': 'Bài hát đã thích',
          'subtitle_text': 'Playlist',
          'cover_url': null, 
        });
      }
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final itemType = item['__type'] ?? 'unknown';
        final isArtist = itemType == 'artist';
        
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
                  itemType == 'album' ? Icons.album : 
                  (itemType == 'playlist' ? Icons.queue_music : 
                  (itemType == 'artist' ? Icons.person : Icons.music_note))
                ),
              ),
            ),
          ),
          title: Text(item['title'] ?? item['name'] ?? 'Không có tiêu đề'),
          subtitle: Text(
            item['subtitle_text'] ?? 'Không rõ',
            style: const TextStyle(color: Colors.grey),
          ),
          onTap: () => _onItemTapped(item),
        );
      },
    );
  }

  // Hàm render danh sách (GridView)
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
                        itemType == 'album' ? Icons.album : 
                        (itemType == 'playlist' ? Icons.queue_music : 
                        (itemType == 'artist' ? Icons.person : Icons.music_note))
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'] ?? item['name'] ?? '', 
                style: const TextStyle(fontWeight: FontWeight.bold), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
              Text(
                item['subtitle_text'] ?? 'Không rõ', 
                style: const TextStyle(color: Colors.grey, fontSize: 12), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
            ],
          ),
        );
      },
    );
  }

  // Lọc dữ liệu từ DataLoaded state
  List<Map<String, dynamic>> _getFilteredData(DataLoaded state) {
    switch (_selectedFilter) {
      case 'Tất cả': 
      case 'Playlist': 
        return state.playlists.map((p) => {
          ...p,
          '__type': 'playlist',
          'subtitle_text': 'Playlist • Buzzify'
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

  // --- SỬA LOGIC NAVIGATION ---
  // Xử lý khi nhấn vào item
  void _onItemTapped(Map<String, dynamic> item) {
     // Ẩn AppBar chính khi điều hướng
     widget.onNavigationChanged?.call(false);
     
     Widget destinationPage;

     switch (item['__type']) {
        case 'liked_songs':
          print("Chuyển đến trang Bài hát đã thích (chưa tạo)");
          widget.onNavigationChanged?.call(true); // Hiện lại AppBar
          return; // Dừng
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
          widget.onNavigationChanged?.call(true); // Hiện lại AppBar
          return; // Dừng
     }
     
     // Điều hướng
     Navigator.of(context).push(
       MaterialPageRoute(builder: (_) => destinationPage),
     ).then((_) {
       // Hiện lại AppBar chính khi quay về
       widget.onNavigationChanged?.call(true);
     });
  }
}