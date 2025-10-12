import 'package:flutter/material.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/mock_data.dart';
import 'package:buzzify/pages/albums.dart';
import 'package:buzzify/pages/play_song.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    // Ban đầu, hiển thị tất cả bài hát
    _searchResults = List.from(mockSongs);

    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        // Nếu ô tìm kiếm trống, hiển thị lại tất cả bài hát
        _searchResults = List.from(mockSongs);
      });
      return;
    }

    // Lọc từ danh sách bài hát và album
    final List<Map<String, dynamic>> filteredList = [];

    // Lọc bài hát
    filteredList.addAll(
      mockSongs.where((song) {
        final title = song['title']?.toLowerCase() ?? '';
        final artist = song['artist']?.toLowerCase() ?? '';
        return title.contains(query) || artist.contains(query);
      }),
    );

    // Lọc album
    filteredList.addAll(
      mockAlbums.where((album) {
        final title = album['title']?.toLowerCase() ?? '';
        final artist = album['artist']?.toLowerCase() ?? '';
        return title.contains(query) || artist.contains(query);
      }),
    );

    setState(() {
      _searchResults = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        // Không cần AppBar vì HomePage đã có title rồi
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // --- Ô tìm kiếm ---
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bài hát, nghệ sĩ...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.darkGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Danh sách kết quả ---
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy kết quả.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        final isAlbum = item.containsKey('songs');

                        return ListTile(
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                isAlbum ? 8.0 : 4.0,
                              ),
                              child: Image.asset(
                                item['cover'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(item['title'] ?? 'Không có tiêu đề'),
                          subtitle: Text(
                            isAlbum
                                ? 'Album • ${item['artist'] ?? 'Không rõ'}'
                                : item['artist'] ?? 'Không rõ nghệ sĩ',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          onTap: () {
                            // Ẩn bàn phím khi nhấn vào kết quả
                            FocusScope.of(context).unfocus();

                            if (isAlbum) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AlbumPage(
                                    album: item,
                                    allSongs: mockSongs,
                                  ),
                                ),
                              );
                            } else {
                              // Tìm vị trí của bài hát trong danh sách gốc để next/prev
                              final originalIndex = mockSongs.indexWhere(
                                (song) => song['file'] == item['file'],
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlaySongPage(
                                    playlist: mockSongs,
                                    initialIndex: originalIndex != -1
                                        ? originalIndex
                                        : 0,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
