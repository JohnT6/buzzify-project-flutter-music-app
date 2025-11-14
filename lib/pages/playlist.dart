// lib/pages/playlist_page.dart
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import 'package:buzzify/common/formatters.dart';
import 'package:buzzify/services/api_playlist_service.dart'; 
import 'package:buzzify/widgets/music_visualizer.dart'; 

class PlaylistPage extends StatefulWidget {
  final Map<String, dynamic> playlist; 
  const PlaylistPage({required this.playlist, super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  Color _dynamicColor = AppColors.darkBackground;
  
  Map<String, dynamic>? _fullPlaylistData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlaylistDetails();
  }

  Future<void> _fetchPlaylistDetails() async {
    try {
      final service = context.read<ApiPlaylistService>();
      final String playlistId = widget.playlist['id'];
      final data = await service.getPlaylistById(playlistId);
      
      if (!mounted) return;
      setState(() {
        _fullPlaylistData = data; 
        _isLoading = false;
      });
      _updateBackgroundColor(_fullPlaylistData?['cover_url']);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBackgroundColor(String? coverUrl) async {
    if (coverUrl == null || !mounted) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(coverUrl), 
      );
      if (mounted) {
        setState(() => _dynamicColor = palette.dominantColor?.color ?? AppColors.darkBackground);
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
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _fullPlaylistData == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(backgroundColor: Colors.transparent, leading: const BackButton()),
        body: Center(child: Text('Lỗi tải playlist: $_error')),
      );
    }

    final playlistData = _fullPlaylistData!;
    final List<Map<String, dynamic>> playlistSongs = List.from(playlistData['songs'] ?? []);
    final coverUrl = playlistData['cover_url']; 
    final String thisContextId = 'playlist-${playlistData['id']}'; 

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
                  padding: const EdgeInsets.only(top: 90, bottom: 20, left: 40, right: 40),
                  child: Hero(
                    tag: 'playlist-cover-${widget.playlist['id']}', 
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlistData['title'] ?? 'Không có tiêu đề',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      playlistData['description'] ?? (playlistData['artists']?['name'] ?? 'Không rõ'),
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: 'Lưu playlist', onPressed: () {}),
                        IconButton(icon: const Icon(Icons.more_vert), tooltip: 'Tùy chọn khác', onPressed: () {}),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.shuffle), tooltip: 'Phát trộn bài', onPressed: () {}),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          onPressed: () {
                            if (playlistSongs.isNotEmpty) {
                              context.read<AudioPlayerBloc>().add(StartPlaying(
                                playlist: playlistSongs, 
                                index: 0, 
                                playlistTitle: playlistData['title'],
                                contextId: thisContextId,
                              ));
                            }
                          },
                          backgroundColor: AppColors.primary,
                          child: const Icon(Icons.play_arrow, size: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bọc SliverList bằng BlocBuilder
            BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
              builder: (context, audioState) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = playlistSongs[index];
                      final songCoverUrl = song['cover_url'];
                      
                      final bool isPlayingThisSong = 
                          audioState.currentSong != null &&
                          audioState.currentSong!['id'] == song['id'] &&
                          audioState.contextId == thisContextId;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: CachedNetworkImage(imageUrl: songCoverUrl, width: 50, height: 50, fit: BoxFit.cover),
                        ),
                        
                        title: Row(
                          children: [
                            if (isPlayingThisSong)
                              MusicVisualizer(isPlaying: audioState.isPlaying), 
                            if (isPlayingThisSong)
                              const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                song['title'] ?? 'Không có tiêu đề',
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
                        subtitle: Text(buildArtistString(song)),
                        
                        // --- SỬA LỖI TẠI ĐÂY ---
                        // Luôn hiển thị icon 3 chấm, không hiển thị visualizer
                        trailing: const Icon(Icons.more_vert), 
                        // --- KẾT THÚC SỬA LỖI ---
                        
                        onTap: () {
                          context.read<AudioPlayerBloc>().add(StartPlaying(
                            playlist: playlistSongs, 
                            index: index,
                            playlistTitle: playlistData['title'],
                            contextId: thisContextId,
                          ));
                        },
                      );
                    },
                    childCount: playlistSongs.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}