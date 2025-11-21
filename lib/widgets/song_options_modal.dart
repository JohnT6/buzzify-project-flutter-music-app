// lib/widgets/song_options_modal.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/common/formatters.dart';
import 'package:buzzify/pages/albums.dart';
import 'package:buzzify/pages/artist.dart';
import 'package:buzzify/services/api_song_service.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:buzzify/blocs/data/data_bloc.dart'; // <-- Import DataBloc

// Hàm nhận vào parentContext để giữ BottomBar khi chuyển trang
void showSongOptionsModal(BuildContext parentContext, Map<String, dynamic> song, {Function(bool)? onNavigationChanged}) {
  final imageUrl = song['cover_url'];
  // --- QUAN TRỌNG: Ép kiểu ID về String để so sánh ---
  final songId = song['id'].toString(); 

  showModalBottomSheet(
    context: parentContext,
    backgroundColor: AppColors.darkGrey,
    useRootNavigator: true, 
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (modalContext) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30.0, top: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh nắm kéo
              Container(
                height: 5,
                width: 40,
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              // Header bài hát
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[850]),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                title: Text(
                  song['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(buildArtistString(song)),
              ),
              const Divider(color: Colors.grey),

              // --- 1. NÚT THÍCH (ĐÃ ĐỒNG BỘ) ---
              BlocBuilder<DataBloc, DataState>(
                // Lấy DataBloc từ parentContext vì modalContext là con của modal route (thường không có provider)
                bloc: parentContext.read<DataBloc>(), 
                builder: (context, state) {
                  bool isLiked = false;
                  if (state is DataLoaded) {
                    isLiked = state.likedSongIds.contains(songId);
                  }
                  return ListTile(
                    leading: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppColors.primary : Colors.white,
                    ),
                    title: Text(isLiked ? 'Đã thích' : 'Thích'),
                    onTap: () {
                      // Gửi sự kiện ToggleLikeSong
                      parentContext.read<DataBloc>().add(ToggleLikeSong(songId));
                    },
                  );
                },
              ),
              // --------------------------------

              // 2. Xem Album
              ListTile(
                leading: const Icon(Icons.album, color: Colors.white),
                title: const Text('Xem album'),
                onTap: () {
                  Navigator.pop(modalContext);

                  if (song['id_album'] != null) {
                    final albumData = {
                      'id': song['id_album'],
                      'title': song['album_name'] ?? 'Album',
                      'cover_url': song['cover_url'],
                      'artists': song['artists'],
                    };

                    onNavigationChanged?.call(false);

                    Navigator.of(parentContext).push(
                      MaterialPageRoute(
                        builder: (_) => AlbumPage(album: albumData),
                      ),
                    ).then((_) {
                      onNavigationChanged?.call(true);
                    });
                  } else {
                     ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(content: Text('Bài hát này không thuộc album nào.')),
                    );
                  }
                },
              ),

              // 3. Xem Nghệ sĩ
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text('Xem nghệ sĩ'),
                onTap: () {
                  Navigator.pop(modalContext);

                  if (song['artist_id'] != null) {
                    final artistData = {
                      'id': song['artist_id'],
                      'name': song['artists']?['name'] ?? 'Nghệ sĩ',
                      'avatar_url': null, 
                    };

                    onNavigationChanged?.call(false);

                    Navigator.of(parentContext).push(
                      MaterialPageRoute(
                        builder: (_) => ArtistPage(artist: artistData),
                      ),
                    ).then((_) {
                      onNavigationChanged?.call(true);
                    });
                  } else {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(content: Text('Không tìm thấy thông tin nghệ sĩ.')),
                    );
                  }
                },
              ),

              // Các nút khác
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.white),
                title: const Text('Thêm vào playlist'),
                onTap: () {
                  Navigator.pop(modalContext);
                  // TODO: Logic thêm playlist
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: const Text('Chia sẻ'),
                onTap: () {
                   Navigator.pop(modalContext);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}