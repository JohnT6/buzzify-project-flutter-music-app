// lib/pages/search.dart
import 'dart:async'; 
import 'dart:math'; 
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:buzzify/pages/albums.dart';
import 'package:buzzify/pages/playlist.dart'; // Sửa tên file
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buzzify/services/api_search_service.dart';
import 'package:buzzify/widgets/music_visualizer.dart';
import 'package:buzzify/blocs/data/data_bloc.dart';
import 'package:buzzify/pages/artist.dart'; // Import ArtistPage

// Enum để quản lý 4 trạng thái của trang Search
enum SearchStatus {
  initial, // 1. Trang "Khám phá"
  focused, // 2. Nhấn vào, hiện "Gợi ý ngẫu nhiên"
  typing,  // 3. Đang gõ, hiện "Gợi ý Live"
  loading, // Đang tải...
  results  // 4. Nhấn Enter, hiện "Kết quả + Chips"
}

class SearchPage extends StatefulWidget {
  // --- THÊM HÀM CALLBACK ---
  final Function(bool)? onNavigationChanged;
  const SearchPage({super.key, this.onNavigationChanged});
  // --- KẾT THÚC THÊM ---
  
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  late ApiSearchService _apiSearchService;
  
  // Quản lý trạng thái UI
  SearchStatus _status = SearchStatus.initial;
  bool _isLoading = false; 
  
  // Dữ liệu
  Timer? _debounce;
  List<Map<String, dynamic>> _apiResults = [];
  List<Map<String, dynamic>> _randomSuggestions = []; 
  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Bài hát', 'Nghệ sĩ', 'Album', 'Playlist', 'Hồ sơ'];

  // DỮ LIỆU GIẢ
  final List<String> _mockKeywordSuggestions = ['v-pop', 'v-pop hits', 'ballad', 'ballad tâm trạng', 'hiphop', 'rap việt'];

  @override
  void initState() {
    super.initState();
    _apiSearchService = context.read<ApiSearchService>();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  void _onFocusChanged() {
    if (_focusNode.hasFocus && _searchController.text.isEmpty) {
      _generateRandomSuggestions(); 
      setState(() => _status = SearchStatus.focused); 
    } 
    else if (!_focusNode.hasFocus && _searchController.text.isEmpty) {
       setState(() => _status = SearchStatus.initial); 
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      
      if (_focusNode.hasFocus) { 
        if (query.isEmpty) {
          _generateRandomSuggestions();
          setState(() => _status = SearchStatus.focused); 
        } else {
          _fetchLiveSuggestions(query); 
        }
      }
    });
  }

  Future<void> _fetchLiveSuggestions(String query) async {
    if (_status != SearchStatus.typing && _status != SearchStatus.focused) {
      if(_searchController.text.isEmpty) {
        _generateRandomSuggestions();
        setState(() => _status = SearchStatus.focused);
      }
      return; 
    }

    setState(() {
      _status = SearchStatus.typing;
      _isLoading = true;
    });

    try {
      final results = await _apiSearchService.search(query);
      if (mounted) {
        setState(() {
          _apiResults = results;
          _isLoading = false; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Lỗi tìm kiếm live: $e");
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    _focusNode.unfocus(); 
    setState(() => _status = SearchStatus.loading); 

    try {
      final results = await _apiSearchService.search(query);
      if (mounted) {
        setState(() {
          _apiResults = results;
          _status = SearchStatus.results; 
          _selectedFilter = 'Tất cả'; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = SearchStatus.focused);
      print("Lỗi tìm kiếm: $e");
    }
  }
  
  void _generateRandomSuggestions() {
    final dataState = context.read<DataBloc>().state;
    if (dataState is DataLoaded) {
      final random = Random();
      List<Map<String, dynamic>> suggestions = [];

      if (dataState.songs.isNotEmpty) {
        suggestions.add(dataState.songs[random.nextInt(dataState.songs.length)]);
      }
      if (dataState.albums.isNotEmpty) {
        suggestions.add(dataState.albums[random.nextInt(dataState.albums.length)]);
      }
       if (dataState.artists.isNotEmpty) {
        suggestions.add(dataState.artists[random.nextInt(dataState.artists.length)]);
      }
      if (dataState.playlists.isNotEmpty) {
        suggestions.add(dataState.playlists[random.nextInt(dataState.playlists.length)]);
      }
      
      suggestions.shuffle(); 
      _randomSuggestions = suggestions.take(4).toList(); 
    }
  }


  // --- HÀM BUILD GIAO DIỆN ---

  @override
  Widget build(BuildContext context) {
    // --- XÓA APPBAR ---
    // AppBar sẽ được cung cấp bởi HomePage
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Column(
        children: [
          _buildSearchBar(), // Tự build 1 thanh search
          Expanded(child: _buildBodyContent()),
        ],
      ),
    );
  }

  // Widget thanh tìm kiếm (thay thế AppBar)
  Widget _buildSearchBar() {
    bool showCancel = _status != SearchStatus.initial;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8), // Padding cho thanh search
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onSubmitted: (query) => _performSearch(query.trim()),
              decoration: InputDecoration(
                hintText: 'Bạn muốn tìm gì?',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => _searchController.clear())
                    : null,
                fillColor: AppColors.darkGrey,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: showCancel ? 60.0 : 0.0, 
            child: ClipRect(
              child: SizedBox(
                width: 60.0,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _apiResults = [];
                      _status = SearchStatus.initial;
                      _focusNode.unfocus();
                    });
                  },
                  child: const Text(
                    'Hủy', 
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // --- KẾT THÚC SỬA ---

  // Nội dung Body
  Widget _buildBodyContent() {
    switch (_status) {
      case SearchStatus.initial:
        return _buildDiscoveryPage();
      case SearchStatus.focused:
        return _buildRandomSuggestions();
      case SearchStatus.typing:
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildResultList(_apiResults, 'search-typing');
      case SearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchStatus.results:
        return _buildResultsPage();
    }
  }

  // 1. Giao diện "Khám phá"
  Widget _buildDiscoveryPage() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // children: [
        //   Text("Khám phá nội dung mới mẻ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        //   SizedBox(height: 16),
        //   Text("Duyệt tìm tất cả", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        // ],
      ),
    );
  }

  // 2. Giao diện "Gợi ý ngẫu nhiên"
  Widget _buildRandomSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 10), // Giảm padding top
          child: Text("Gợi ý cho bạn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: _buildResultList(_randomSuggestions, 'random-suggestions'),
        ),
      ],
    );
  }

  // 4. Giao diện "Kết quả" (Sau khi Enter)
  Widget _buildResultsPage() {
    return Column(
      children: [
        _buildFilterChips(), 
        Expanded(
          child: _buildResultList(_getFilteredResults(), 'search-results'),
        ),
      ],
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
                color: isSelected ? Colors.white : Colors.white,
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

  // Hàm lọc kết quả
  List<Map<String, dynamic>> _getFilteredResults() {
    if (_selectedFilter == 'Tất cả') {
      return _apiResults;
    }
    final typeMap = {
      'Bài hát': 'song',
      'Nghệ sĩ': 'artist',
      'Album': 'album',
      'Playlist': 'playlist',
      'Hồ sơ': 'profile',
    };
    final filterType = typeMap[_selectedFilter];
    return _apiResults.where((item) => item['__type'] == filterType).toList();
  }

  // Widget render 1 danh sách
  Widget _buildResultList(List<Map<String, dynamic>> results, String contextId) {
    if (results.isEmpty) {
      if ((_status == SearchStatus.results || _status == SearchStatus.typing) && _searchController.text.isNotEmpty) {
         return const Center(child: Text("Không tìm thấy kết quả.", style: TextStyle(color: Colors.grey)));
      }
      return const Center(child: Text("Không có nội dung.", style: TextStyle(color: Colors.grey)));
    }
    
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, audioState) {
        final currentSong = audioState.currentSong;

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            final itemType = item['__type'] ?? 'song';
            final isSongItem = itemType == 'song';
            final imageUrl = item['cover_url'] ?? item['avatar_url'];

            final bool isPlayingThisSong = isSongItem &&
                currentSong != null &&
                currentSong['id'] == item['id'] &&
                audioState.contextId == contextId;

            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(itemType == 'artist' || itemType == 'profile' ? 25.0 : 4.0),
                child: CachedNetworkImage(
                  imageUrl: imageUrl ?? '', 
                  width: 50, height: 50, 
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Container(
                    width: 50, height: 50, 
                    color: AppColors.darkGrey,
                    child: Icon(_getIconForItemType(itemType)),
                  ),
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
                      item['title'] ?? item['name'] ?? 'Không có tiêu đề',
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
              subtitle: Text(
                item['subtitle_text'] ?? 'Không rõ',
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () => _onItemTapped(item, contextId),
            );
          },
        );
      },
    );
  }

  // Hàm lấy icon (dùng cho ảnh lỗi)
  IconData _getIconForItemType(String type) {
    switch (type) {
      case 'song': return Icons.music_note;
      case 'album': return Icons.album;
      case 'artist': return Icons.person_outline;
      case 'playlist': return Icons.queue_music;
      case 'profile': return Icons.account_circle_outlined;
      default: return Icons.error;
    }
  }

  // Hàm xử lý khi nhấn vào 1 item
  void _onItemTapped(Map<String, dynamic> item, String contextId) {
     // --- SỬA LOGIC NAVIGATION ---
     // Ẩn AppBar chính khi điều hướng
     widget.onNavigationChanged?.call(false);
     
     // Biến để lưu trang sẽ điều hướng tới
     Widget destinationPage;

     switch (item['__type']) {
        case 'song':
          final dataState = context.read<DataBloc>().state;
          if (dataState is DataLoaded) {
            final allSongs = dataState.songs;
            final int songIndex = allSongs.indexWhere((s) => s['id'] == item['id']);

            if (songIndex != -1) {
                context.read<AudioPlayerBloc>().add(
                  StartPlaying(
                    playlist: allSongs, 
                    index: songIndex,
                    playlistTitle: "Tìm kiếm", 
                    contextId: contextId,
                  ),
                );
            }
          }
          // Sau khi phát nhạc, KHÔNG điều hướng, chỉ hiện lại AppBar
          widget.onNavigationChanged?.call(true);
          return; // Dừng hàm ở đây

        case 'album':
          destinationPage = AlbumPage(album: item);
          break;
        case 'playlist':
          destinationPage = PlaylistPage(playlist: item);
          break;
        case 'artist':
          destinationPage = ArtistPage(artist: item);
          break;
        case 'profile':
          // destinationPage = ProfilePage(profile: item);
          print("Chuyển đến trang hồ sơ (chưa tạo)");
          widget.onNavigationChanged?.call(true); // Hiện lại AppBar
          return; // Dừng
        default:
          widget.onNavigationChanged?.call(true); // Hiện lại AppBar
          return; // Dừng
     }
     
     // Thực hiện điều hướng
     Navigator.of(context).push(
       MaterialPageRoute(builder: (_) => destinationPage),
     ).then((_) {
       // Hiện lại AppBar chính khi quay về
       widget.onNavigationChanged?.call(true);
     });
  }
}