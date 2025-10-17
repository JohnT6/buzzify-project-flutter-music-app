import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlbumPage extends StatelessWidget {
  final Map<String, dynamic> album;
  // XÓA BỎ: không cần allSongs nữa
  const AlbumPage({required this.album, super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách bài hát từ chính dữ liệu album (nếu đã fetch từ Supabase)
    final List<Map<String, dynamic>> albumSongs = List.from(album['songs'] ?? []);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: AppColors.darkBackground,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(album['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              centerTitle: true,
              // ...
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ...
                  ElevatedButton.icon(
                    // ...
                    label: const Text('Phát tất cả'),
                    onPressed: () {
                      // THAY ĐỔI: Gửi Event đến BLoC
                      if (albumSongs.isNotEmpty) {
                        context.read<AudioPlayerBloc>().add(
                          StartPlaying(playlist: albumSongs, index: 0),
                        );
                      }
                    },
                  ),
                  // ...
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = albumSongs[index];
                return ListTile(
                  // ...
                  onTap: () {
                    // THAY ĐỔI: Gửi Event đến BLoC
                    context.read<AudioPlayerBloc>().add(
                      StartPlaying(playlist: albumSongs, index: index),
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