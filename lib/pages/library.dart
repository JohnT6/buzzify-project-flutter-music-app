// lib/pages/library.dart
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:buzzify/blocs/data/data_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:buzzify/pages/albums.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return <Widget>[
              const SliverAppBar(
                pinned: true,
                floating: true,
                title: Text('Thư viện'),
                centerTitle: true,
                automaticallyImplyLeading: false,
                bottom: TabBar(
                  indicatorColor: AppColors.primary,
                  tabs: [Tab(text: 'Bài hát đã thích'), Tab(text: 'Albums đã lưu')],
                ),
              ),
            ];
          },
          body: BlocBuilder<DataBloc, DataState>(
            builder: (context, state) {
              if (state is DataLoading) return const Center(child: CircularProgressIndicator());
              if (state is DataLoaded) {
                // Sau này, bạn sẽ fetch từ bảng liked_songs và saved_albums
                final likedSongs = state.songs; // Tạm lấy tất cả bài hát
                final savedAlbums = state.albums; // Tạm lấy tất cả albums

                return TabBarView(
                  children: [
                    _buildLikedSongsList(context, likedSongs, state.songs),
                    _buildAlbumsGrid(context, savedAlbums),
                  ],
                );
              }
              if (state is DataError) return Center(child: Text('Lỗi: ${state.message}'));
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLikedSongsList(BuildContext context, List<Map<String, dynamic>> likedSongs, List<Map<String, dynamic>> allSongs) {
    if (likedSongs.isEmpty) return const Center(child: Text('Bạn chưa thích bài hát nào.', style: TextStyle(color: Colors.grey)));
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: likedSongs.length,
      itemBuilder: (context, index) {
        final song = likedSongs[index];
        final imageUrl = Supabase.instance.client.storage.from('Buzzify').getPublicUrl(song['cover_url']);
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
          ),
          title: Text(song['title'] ?? 'Không có tiêu đề'),
          subtitle: Text(song['artists']?['name'] ?? 'Không rõ nghệ sĩ'),
          onTap: () {
            context.read<AudioPlayerBloc>().add(
                  StartPlaying(playlist: allSongs, index: index),
                );
          },
        );
      },
    );
  }

  Widget _buildAlbumsGrid(BuildContext context, List<Map<String, dynamic>> albums) {
    if (albums.isEmpty) return const Center(child: Text('Bạn chưa lưu album nào.', style: TextStyle(color: Colors.grey)));
    
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0, childAspectRatio: 0.8,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final imageUrl = Supabase.instance.client.storage.from('Buzzify').getPublicUrl(album['cover_url']);
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlbumPage(album: album))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
                ),
              ),
              const SizedBox(height: 8),
              Text(album['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(album['artists']?['name'] ?? 'Không rõ', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }
}