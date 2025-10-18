import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import 'package:buzzify/common/formatters.dart';

class AlbumPage extends StatefulWidget {
  final Map<String, dynamic> album;
  const AlbumPage({required this.album, super.key});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  Color _dynamicColor = AppColors.darkBackground; // Đổi tên để rõ nghĩa hơn

  @override
  void initState() {
    super.initState();
    _updateBackgroundColor(widget.album['cover_url']);
  }

  Future<void> _updateBackgroundColor(String? coverUrl) async {
    if (coverUrl == null || !mounted) return;
    final publicUrl = Supabase.instance.client.storage.from('Buzzify').getPublicUrl(coverUrl);
    try {
      final palette = await PaletteGenerator.fromImageProvider(CachedNetworkImageProvider(publicUrl));
      if (mounted) {
        setState(() => _dynamicColor = palette.dominantColor?.color ?? AppColors.darkBackground);
      }
    } catch (e) {
      // Giữ màu mặc định nếu có lỗi
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> albumSongs = List.from(widget.album['songs'] ?? []);
    final coverUrl = Supabase.instance.client.storage.from('Buzzify').getPublicUrl(widget.album['cover_url']);

    final int totalDurationSeconds = albumSongs.fold<int>(0, (sum, song) => sum + (song['duration_seconds'] as int? ?? 0));
    final int minutes = totalDurationSeconds ~/ 60;
    final int seconds = totalDurationSeconds % 60;
    final String totalDurationString = '${minutes} phút ${seconds} giây';

    // --- THAY ĐỔI 1: Bọc toàn bộ Scaffold trong một Container có Gradient ---
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,    // Hướng đổ từ trên
          end: Alignment.bottomCenter,  // xuống dưới
          colors: [
            _dynamicColor, // Màu bắt đầu (lấy từ ảnh bìa, giảm độ trong suốt một chút)
            AppColors.darkBackground,     // Màu kết thúc (màu nền chính của app)
          ],
          // --- ĐIỂM DỪNG MÀU ---
          // 0.0: Màu bắt đầu ở trên cùng
          // 0.5: Quá trình chuyển màu sẽ hoàn tất ở nửa màn hình. Nửa dưới sẽ là màu nền chính.
          // Bạn có thể thay đổi số 0.5 thành 0.6, 0.7... để gradient kéo dài hơn.
          stops: const [0.0, 1],
        ),
      ),
      child: Scaffold(
        // --- THAY ĐỔI 2: Cho nền Scaffold trong suốt để thấy được Gradient ---
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 350.0,
              pinned: true,
              stretch: true,
              // --- THAY ĐỔI 3: Nền SliverAppBar cũng trong suốt ---
              backgroundColor: Colors.transparent,
              elevation: 0, // Bỏ đổ bóng để liền mạch hơn
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  // Thêm padding top để ảnh bìa không bị che bởi status bar
                  padding: const EdgeInsets.only(top: 90, bottom: 20, left: 40, right: 40),
                  child: Hero(
                    tag: 'album-cover-${widget.album['id']}',
                    child: Material(
                      elevation: 15,
                      borderRadius: BorderRadius.circular(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              // --- THAY ĐỔI 4: Bỏ màu nền của Container này để không còn bị chia 2 phần ---
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.album['title'] ?? 'Không có tiêu đề',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.album['artists']?['name'] ?? 'Không rõ',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Album • $totalDurationString',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: 'Lưu album', onPressed: () {}),
                        IconButton(icon: const Icon(Icons.more_vert), tooltip: 'Tùy chọn khác', onPressed: () {}),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.shuffle), tooltip: 'Phát trộn bài', onPressed: () {}),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          onPressed: () {
                            if (albumSongs.isNotEmpty) {
                              context.read<AudioPlayerBloc>().add(StartPlaying(playlist: albumSongs, index: 0));
                            }
                          },
                          backgroundColor: AppColors.primary,
                          child: const Icon(Icons.play_arrow, size: 30),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = albumSongs[index];
                  final songCoverUrl = Supabase.instance.client.storage.from('Buzzify').getPublicUrl(song['cover_url']);
                  
                  // ListTile sẽ tự có nền trong suốt, nên sẽ thấy được gradient
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: CachedNetworkImage(imageUrl: songCoverUrl, width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    title: Text(song['title'] ?? 'Không có tiêu đề'),
                    subtitle: Text(buildArtistString(song)),
                    trailing: const Icon(Icons.more_vert),
                    onTap: () {
                      context.read<AudioPlayerBloc>().add(StartPlaying(playlist: albumSongs, index: index));
                    },
                  );
                },
                childCount: albumSongs.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}