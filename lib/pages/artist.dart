import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/pages/albums.dart';
import 'package:buzzify/services/api_artist_service.dart';
import 'package:buzzify/widgets/music_visualizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:palette_generator/palette_generator.dart';

class ArtistPage extends StatefulWidget {
  final Map<String, dynamic> artist;
  const ArtistPage({super.key, required this.artist});

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  Color _dynamicColor = AppColors.darkBackground;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _popularSongs = [];
  List<Map<String, dynamic>> _artistAlbums = [];
  
  // Biến lưu trữ thông tin đầy đủ của nghệ sĩ (sau khi fetch lại)
  late Map<String, dynamic> _fullArtistData;
  String? _error;

  final String _monthlyListeners = "46,7 Tr người nghe hàng tháng";
  bool _isFollowing = true;

  @override
  void initState() {
    super.initState();
    // Khởi tạo bằng dữ liệu truyền vào (có thể thiếu ảnh)
    _fullArtistData = widget.artist;
    _fetchArtistData();
  }

  Future<void> _fetchArtistData() async {
    try {
      final service = context.read<ApiArtistService>();
      final artistId = widget.artist['id'];

      // Gọi song song 3 API:
      // 1. Lấy lại thông tin chi tiết Artist (để có ảnh avatar)
      // 2. Lấy bài hát
      // 3. Lấy album
      final responses = await Future.wait([
        service.getArtistById(artistId), // Hàm này cần có trong ApiArtistService
        service.getSongsByArtistId(artistId),
        service.getAlbumsByArtistId(artistId),
      ]);

      if (!mounted) return;
      setState(() {
        _fullArtistData = responses[0] as Map<String, dynamic>; // Cập nhật info đầy đủ
        _popularSongs = responses[1] as List<Map<String, dynamic>>;
        _artistAlbums = responses[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
      
      // Cập nhật màu nền dựa trên ảnh mới lấy được
      _updateBackgroundColor(_fullArtistData['avatar_url']);

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
    // Sử dụng _fullArtistData thay vì widget.artist
    final artistName = _fullArtistData['name'] ?? 'Không rõ';
    final artistImage = _fullArtistData['avatar_url'];
    final thisContextId = 'artist-${_fullArtistData['id']}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_dynamicColor, AppColors.darkBackground],
          stops: const [0.0, 0.5],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 400.0,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                // title: Text(
                //   artistName,
                //   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                // ),
                // centerTitle: false,
                // titlePadding: const EdgeInsetsDirectional.only(start: 60, bottom: 16),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: artistImage ?? '',
                      fit: BoxFit.cover,
                      // Hiển thị màu xám nếu chưa có ảnh
                      errorWidget: (c, u, e) => Container(color: AppColors.darkGrey),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 80,
                      left: 16,
                      child: Text(
                        artistName,
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 10.0, color: Colors.black)],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      left: 18,
                      child: Text(
                        _monthlyListeners,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                  builder: (context, audioState) {
                    final isContextMatch = audioState.contextId == thisContextId;
                    final isPlaying = isContextMatch && audioState.isPlaying;
                    final isShuffling = audioState.isShuffling;

                    return Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() => _isFollowing = !_isFollowing);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54, width: 1.5),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            _isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white54),
                          onPressed: () {},
                        ),
                        const Spacer(),
                        
                        // NÚT TRỘN BÀI
                        IconButton(
                          icon: Icon(
                            Icons.shuffle, 
                            color: isShuffling ? AppColors.primary : Colors.white, 
                            size: 28
                          ),
                          onPressed: () {
                            context.read<AudioPlayerBloc>().add(ToggleShuffleRequested());
                          },
                        ),
                        const SizedBox(width: 8),
                        
                        // NÚT PHÁT HÌNH TRÒN (CircleBorder)
                        FloatingActionButton(
                          onPressed: () {
                            if (isPlaying) {
                              context.read<AudioPlayerBloc>().add(PauseRequested());
                            } else if (isContextMatch) {
                              context.read<AudioPlayerBloc>().add(PlayRequested());
                            } else {
                              if (_popularSongs.isNotEmpty) {
                                context.read<AudioPlayerBloc>().add(StartPlaying(
                                  playlist: _popularSongs,
                                  index: 0,
                                  playlistTitle: 'Bài hát phổ biến: $artistName',
                                  contextId: thisContextId,
                                ));
                              }
                            }
                          },
                          backgroundColor: AppColors.primary,
                          // Đảm bảo nút luôn tròn
                          shape: const CircleBorder(), 
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow, 
                            size: 30, 
                            color: Colors.white
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'Popular',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            _buildPopularList(thisContextId),
            
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'Albums',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            _buildAlbumList(),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularList(String thisContextId) {
    if (_isLoading) {
      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return SliverToBoxAdapter(child: Center(child: Text('Lỗi: $_error')));
    }
    
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, audioState) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= _popularSongs.length) return null;
              final song = _popularSongs[index];
              final songCoverUrl = song['cover_url'];

              final bool isPlayingThisSong =
                  audioState.currentSong != null &&
                  audioState.currentSong!['id'] == song['id'] &&
                  audioState.contextId == thisContextId;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: CachedNetworkImage(
                    imageUrl: songCoverUrl ?? '', 
                    width: 40, height: 40, fit: BoxFit.cover,
                    errorWidget: (c,u,e) => Container(width: 40, height: 40, color: AppColors.darkGrey),
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
                trailing: const Icon(Icons.more_vert, color: Colors.grey),
                onTap: () {
                  context.read<AudioPlayerBloc>().add(StartPlaying(
                        playlist: _popularSongs,
                        index: index,
                        playlistTitle: 'Bài hát phổ biến: ${_fullArtistData['name']}',
                        contextId: thisContextId,
                      ));
                },
              );
            },
            childCount: _popularSongs.length,
          ),
        );
      },
    );
  }

  Widget _buildAlbumList() {
    if (_isLoading || _error != null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 230,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: _artistAlbums.length,
          itemBuilder: (context, index) {
            final album = _artistAlbums[index];
            final imageUrl = album['cover_url'];
            
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AlbumPage(album: album)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'album-cover-${album['id']}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[850]),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 150,
                      child: Text(
                        album['title'],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        'Album • ${DateTime.tryParse(album['release_date'] ?? '')?.year ?? ''}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}