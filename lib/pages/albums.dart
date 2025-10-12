import 'package:buzzify/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:buzzify/pages/play_song.dart';

class AlbumPage extends StatelessWidget {
  final Map<String, dynamic> album;
  final List<Map<String, dynamic>> allSongs;

  const AlbumPage({required this.album, required this.allSongs, super.key});

  @override
  Widget build(BuildContext context) {

    final List<Map<String, dynamic>> albumSongs =
        List.from(album['songs'] as List);

    return Scaffold(

      body: CustomScrollView(
        slivers: [

          SliverAppBar(
            expandedHeight: 300.0, 
            pinned: true, 
            backgroundColor: AppColors.darkBackground,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                album['title'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    album['cover'],
                    fit: BoxFit.cover,
                  ),
                  // Lớp phủ tối để chữ dễ đọc hơn
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // SliverToBoxAdapter để chứa các widget thông thường
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Album của ${album['artist']}',
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Phát tất cả'),
                    onPressed: () {
                      // SỬA LẠI ĐIỀU HƯỚNG: Bắt đầu phát từ bài đầu tiên (index 0)
                      if (albumSongs.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaySongPage(
                              playlist: albumSongs,
                              initialIndex: 0,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
              ),
            ),
          ),

          // SliverList để hiển thị danh sách bài hát
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = albumSongs[index];
                return ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.asset(
                        song['cover'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
  
                  title: Text(song['title']!),
                  subtitle: Text(song['artist']!),
                  trailing: const Icon(Icons.more_vert),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaySongPage(
                          playlist: albumSongs,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: albumSongs.length,
            ),
          ),
        ],
      ),
    );
  }
}