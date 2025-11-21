// lib/pages/albums.dart
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import 'package:buzzify/common/formatters.dart';
import 'package:buzzify/services/api_album_service.dart';
// Import widget 3 thanh nhảy
import 'package:buzzify/widgets/music_visualizer.dart';
import 'package:buzzify/widgets/song_options_modal.dart';

class AlbumPage extends StatefulWidget {
  final Map<String, dynamic> album;
  const AlbumPage({required this.album, super.key});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  Color _dynamicColor = AppColors.darkBackground;

  Map<String, dynamic>? _fullAlbumData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAlbumDetails();
  }

  // Hàm gọi API lấy chi tiết album (info + songs)
  Future<void> _fetchAlbumDetails() async {
    try {
      final service = context.read<ApiAlbumService>();
      final String albumId = widget.album['id'];
      final data = await service.getAlbumById(albumId);

      if (!mounted) return;
      setState(() {
        _fullAlbumData = data;
        _isLoading = false;
      });
      _updateBackgroundColor(_fullAlbumData?['cover_url']);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Hàm cập nhật màu nền
  Future<void> _updateBackgroundColor(String? coverUrl) async {
    if (coverUrl == null || !mounted) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(coverUrl),
      );
      if (mounted) {
        setState(
          () => _dynamicColor =
              palette.mutedColor?.color ?? AppColors.darkBackground,
        );
      }
    } catch (e) {
      // Giữ màu mặc định
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: const BackButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _fullAlbumData == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: const BackButton(),
        ),
        body: Center(child: Text('Lỗi tải album: $_error')),
      );
    }

    // Gán dữ liệu khi đã tải xong
    final albumData = _fullAlbumData!;
    final List<Map<String, dynamic>> albumSongs = List.from(
      albumData['songs'] ?? [],
    );
    final coverUrl = albumData['cover_url'];
    // ID CỦA ALBUM HIỆN TẠI (CONTEXT ID)
    final String thisContextId = 'album-${albumData['id']}';

    // Tính tổng thời lượng
    final int totalDurationSeconds = albumSongs.fold<int>(
      0,
      (sum, song) => sum + (song['duration_seconds'] as int? ?? 0),
    );
    final int minutes = totalDurationSeconds ~/ 60;
    final int seconds = totalDurationSeconds % 60;
    final String totalDurationString = '${minutes} phút ${seconds} giây';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_dynamicColor, AppColors.darkBackground],
          stops: const [0.0, 1],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 350.0,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.only(
                    top: 90,
                    bottom: 20,
                    left: 40,
                    right: 40,
                  ),
                  child: Hero(
                    // Dùng ID từ widget.album (để khớp với trang Home)
                    tag: 'album-cover-${widget.album['id']}',
                    child: Material(
                      elevation: 15,
                      borderRadius: BorderRadius.circular(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      albumData['title'] ?? 'Không có tiêu đề',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      albumData['artists']?['name'] ?? 'Không rõ',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Album • $totalDurationString',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                      builder: (context, audioState) {
                        // Kiểm tra xem có đang phát album này không
                        final isContextMatch = audioState.contextId == thisContextId;
                        final isPlaying = isContextMatch && audioState.isPlaying;
                        final isShuffling = audioState.isShuffling;

                        return Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: 'Lưu album',
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Tùy chọn khác',
                              onPressed: () {},
                            ),
                            const Spacer(),
                            
                            // NÚT TRỘN BÀI (SHUFFLE)
                            IconButton(
                              icon: Icon(
                                Icons.shuffle,
                                // Đổi màu khi bật trộn bài
                                color: isShuffling ? AppColors.primary : Colors.white,
                              ),
                              tooltip: 'Phát trộn bài',
                              onPressed: () {
                                context.read<AudioPlayerBloc>().add(ToggleShuffleRequested());
                              },
                            ),
                            const SizedBox(width: 8),
                            
                            // NÚT PHÁT/DỪNG (PLAY/PAUSE)
                            FloatingActionButton(
                              onPressed: () {
                                if (isPlaying) {
                                  // Đang phát -> Dừng
                                  context.read<AudioPlayerBloc>().add(PauseRequested());
                                } else if (isContextMatch) {
                                  // Đang dừng đúng album này -> Tiếp tục phát
                                  context.read<AudioPlayerBloc>().add(PlayRequested());
                                } else {
                                  // Album khác -> Bắt đầu phát mới
                                  if (albumSongs.isNotEmpty) {
                                    context.read<AudioPlayerBloc>().add(
                                      StartPlaying(
                                        playlist: albumSongs,
                                        index: 0,
                                        playlistTitle: 'Album: ${albumData['title']}',
                                        contextId: thisContextId,
                                      ),
                                    );
                                  }
                                }
                              },
                              backgroundColor: AppColors.primary,
                              // Hình dạng tròn (Mặc định FAB đã tròn, nhưng thêm vào cho chắc)
                              shape: const CircleBorder(), 
                              child: Icon(
                                // Đổi icon dựa trên trạng thái
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 30,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bọc SliverList bằng BlocBuilder để sửa lỗi
            BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
              builder: (context, audioState) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = albumSongs[index];
                    final songCoverUrl = song['cover_url'];

                    // Kiểm tra logic (dùng audioState từ builder)
                    final bool isPlayingThisSong =
                        audioState.currentSong != null &&
                        audioState.currentSong!['id'] == song['id'] &&
                        audioState.contextId == thisContextId;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: CachedNetworkImage(
                          imageUrl: songCoverUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // --- SỬA LỖI THEO YÊU CẦU ---
                      title: Row(
                        children: [
                          // 1. Hiển thị Visualizer
                          if (isPlayingThisSong)
                            MusicVisualizer(isPlaying: audioState.isPlaying),
                          if (isPlayingThisSong) const SizedBox(width: 8),

                          // 2. Tên bài hát
                          Expanded(
                            child: Text(
                              song['title'] ?? 'Không có tiêu đề',
                              style: TextStyle(
                                color: isPlayingThisSong
                                    ? AppColors.primary
                                    : null,
                                fontWeight: isPlayingThisSong
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(buildArtistString(song)),

                      // 3. Giữ nguyên icon 3 chấm
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => showSongOptionsModal(context, song),
                      ),

                      // --- KẾT THÚC SỬA LỖI ---
                      onTap: () {
                        context.read<AudioPlayerBloc>().add(
                          StartPlaying(
                            playlist: albumSongs,
                            index: index,
                            playlistTitle: 'Album: ${albumData['title']}',
                            contextId: thisContextId, // Gửi Context ID
                          ),
                        );
                      },
                    );
                  }, childCount: albumSongs.length),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
