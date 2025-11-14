// lib/pages/artist_page.dart
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/common/formatters.dart';
import 'package:buzzify/pages/albums.dart';
import 'package:buzzify/services/api_artist_service.dart';
import 'package:buzzify/widgets/music_visualizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:palette_generator/palette_generator.dart';

class ArtistPage extends StatefulWidget {
  // Nhận thông tin nghệ sĩ cơ bản từ trang Search
  final Map<String, dynamic> artist;
  const ArtistPage({super.key, required this.artist});

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  Color _dynamicColor = AppColors.darkBackground;
  
  // State để lưu dữ liệu tải về
  bool _isLoading = true;
  List<Map<String, dynamic>> _popularSongs = [];
  List<Map<String, dynamic>> _artistAlbums = [];
  String? _error;

  // Mock data (Backend của bạn chưa có)
  final String _monthlyListeners = "46,7 Tr người nghe hàng tháng";
  bool _isFollowing = true;

  @override
  void initState() {
    super.initState();
    _fetchArtistData();
  }

  Future<void> _fetchArtistData() async {
    try {
      final service = context.read<ApiArtistService>();
      final artistId = widget.artist['id'];

      // Gọi API tải bài hát và album song song
      final responses = await Future.wait([
        service.getSongsByArtistId(artistId),
        service.getAlbumsByArtistId(artistId),
      ]);

      if (!mounted) return;
      setState(() {
        _popularSongs = responses[0];
        _artistAlbums = responses[1];
        _isLoading = false;
      });
      _updateBackgroundColor(widget.artist['avatar_url']);

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
    final artistName = widget.artist['name'] ?? 'Không rõ';
    final artistImage = widget.artist['avatar_url'];
    final thisContextId = 'artist-${widget.artist['id']}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_dynamicColor, AppColors.darkBackground],
          stops: const [0.0, 0.7], // Gradient dốc hơn
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
              // Nút Back
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                // Tiêu đề khi thu gọn
                title: Text(
                  artistName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsetsDirectional.only(start: 60, bottom: 16),
                // Nền (Ảnh + Tên)
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Ảnh nghệ sĩ
                    CachedNetworkImage(
                      imageUrl: artistImage ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) => Container(color: AppColors.darkGrey),
                    ),
                    // Lớp phủ Gradient đen ở dưới
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
                    // Tên nghệ sĩ (lớn)
                    Positioned(
                      bottom: 80, // Vị trí tên nghệ sĩ
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
                    // Người nghe hàng tháng
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
            
            // Hàng Nút điều khiển
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Nút Theo dõi
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
                    // Nút Tùy chọn
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                      onPressed: () {},
                    ),
                    const Spacer(),
                    // Nút Phát trộn
                    IconButton(
                      icon: const Icon(Icons.shuffle, color: Colors.white, size: 28),
                      onPressed: () {
                        // TODO: Logic phát trộn
                      },
                    ),
                    const SizedBox(width: 8),
                    // Nút Play FAB
                    FloatingActionButton(
                      onPressed: () {
                        if (_popularSongs.isNotEmpty) {
                          context.read<AudioPlayerBloc>().add(StartPlaying(
                                playlist: _popularSongs,
                                index: 0,
                                playlistTitle: 'Bài hát phổ biến: $artistName',
                                contextId: thisContextId,
                              ));
                        }
                      },
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.play_arrow, size: 30, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // Tiêu đề "Popular"
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'Popular',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Danh sách bài hát "Popular"
            _buildPopularList(thisContextId),
            
            // Tiêu đề "Albums"
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'Albums',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            // Danh sách ngang "Albums"
            _buildAlbumList(),
            
            // Khoảng trống ở dưới
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  // Widget cho danh sách Popular
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
                // Bỏ qua subtitle (giống Spotify)
                trailing: const Icon(Icons.more_vert, color: Colors.grey),
                onTap: () {
                  context.read<AudioPlayerBloc>().add(StartPlaying(
                        playlist: _popularSongs,
                        index: index,
                        playlistTitle: 'Bài hát phổ biến: ${widget.artist['name']}',
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

  // Widget cho danh sách Albums
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
                        // Lấy năm từ 'release_date'
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