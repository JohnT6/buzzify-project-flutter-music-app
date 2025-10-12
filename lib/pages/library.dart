// lib/pages/library.dart

import 'package:buzzify/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:buzzify/pages/albums.dart';
import 'package:buzzify/pages/play_song.dart';

class LibraryPage extends StatelessWidget {
  final List<Map<String, dynamic>> songs;
  final List<Map<String, dynamic>> albums;

  const LibraryPage({
    required this.songs,
    required this.albums,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Lọc ra danh sách các bài hát đã được "like"
    final likedSongs = songs.where((song) => song['isLiked'] == true).toList();

    // Dùng DefaultTabController để quản lý 2 tab
    return DefaultTabController(
      length: 2, // Có 2 tab: Bài hát và Albums
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Dùng NestedScrollView để thanh TabBar trôi theo khi cuộn
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: AppColors.darkBackground,
                pinned: true,
                floating: true,
                // Không cần title vì đã có ở HomePage
                title: const Text('Thư viện của bạn'),
                centerTitle: true,
                automaticallyImplyLeading: false, // Ẩn nút back
                bottom: const TabBar(
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Bài hát đã thích'),
                    Tab(text: 'Albums'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // --- Nội dung cho Tab 1: Bài hát đã thích ---
              _buildLikedSongsList(context, likedSongs),
              // --- Nội dung cho Tab 2: Albums ---
              _buildAlbumsGrid(context, albums),
            ],
          ),
        ),
      ),
    );
  }

  // Widget xây dựng danh sách bài hát
  Widget _buildLikedSongsList(BuildContext context, List<Map<String, dynamic>> likedSongs) {
    if (likedSongs.isEmpty) {
      return const Center(
        child: Text(
          'Bạn chưa thích bài hát nào.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: likedSongs.length,
      itemBuilder: (context, index) {
        final song = likedSongs[index];
        return ListTile(
          leading: SizedBox(
            width: 50,
            height: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: Image.asset(
                song['cover'] ?? 'assets/images/placeholder.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(song['title'] ?? 'Không có tiêu đề'),
          subtitle: Text(song['artist'] ?? 'Không rõ nghệ sĩ'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaySongPage(
                  playlist: likedSongs,
                  initialIndex: index,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget xây dựng lưới albums
  Widget _buildAlbumsGrid(BuildContext context, List<Map<String, dynamic>> albums) {
    if (albums.isEmpty) {
      return const Center(
        child: Text(
          'Không có album nào.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Hiển thị 2 album trên một hàng
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.8, // Tỷ lệ chiều rộng/chiều cao của mỗi item
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlbumPage(
                  album: album,
                  allSongs: songs, // Truyền toàn bộ danh sách bài hát
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    album['cover'] ?? 'assets/images/placeholder.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                album['title'] ?? 'Không có tiêu đề',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                album['artist'] ?? 'Không rõ nghệ sĩ',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}