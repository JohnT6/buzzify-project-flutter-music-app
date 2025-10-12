import 'package:buzzify/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';

class PlaySongPage extends StatefulWidget {
  final List<Map<String, dynamic>> playlist;
  final int initialIndex;

  const PlaySongPage({
    required this.playlist,
    required this.initialIndex,
    super.key,
  });

  @override
  State<PlaySongPage> createState() => _PlaySongPageState();
}

class _PlaySongPageState extends State<PlaySongPage> {
  Color _backgroundColor = AppColors.darkBackground;
  late AudioPlayer _player;
  late int currentIndex;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  // State cho các tính năng mới
  bool isShuffling = false;
  LoopMode loopMode = LoopMode.off;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    currentIndex = widget.initialIndex; // Lấy vị trí bài hát ban đầu
    _loadSong();

    // Lắng nghe các thay đổi từ audio player
    _player.playerStateStream.listen((state) {
      setState(() {
        isPlaying = state.playing;
      });
      if (state.processingState == ProcessingState.completed) {
        _nextSong();
      }
    });
    _player.loopModeStream.listen((mode) => setState(() => loopMode = mode));
    _player.shuffleModeEnabledStream.listen(
      (enabled) => setState(() => isShuffling = enabled),
    );
    _player.positionStream.listen((pos) => setState(() => position = pos));
    _player.durationStream.listen((dur) {
      if (dur != null) setState(() => duration = dur);
    });
  }

  Future<void> _updateBackgroundColor() async {
    final imageProvider = AssetImage(widget.playlist[currentIndex]['cover']!);
    final palette = await PaletteGenerator.fromImageProvider(imageProvider);
    setState(() {
      _backgroundColor =
          palette.darkVibrantColor?.color ??
          palette.vibrantColor?.color ??
          palette.darkMutedColor?.color ??
          AppColors.darkBackground;
    });
  }

  Future<void> _loadSong() async {
    await _updateBackgroundColor();
    final song = widget.playlist[currentIndex];
    await _player.setAsset(song['file']!);
    await _player.play();
  }

  void _togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  void _nextSong() {
    if (currentIndex < widget.playlist.length - 1) {
      setState(() {
        currentIndex++;
      });
      _loadSong();
    }
    // Nếu ở cuối và không lặp lại thì dừng
    else if (loopMode != LoopMode.all) {
      _player.stop();
    }
  }

  void _prevSong() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _loadSong();
    }
  }

  // Xáo trộn bài hát
  void _toggleShuffle() {
    setState(() {
      isShuffling = !isShuffling;
      _player.setShuffleModeEnabled(isShuffling);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isShuffling ? 'Đã bật xáo trộn' : 'Đã tắt xáo trộn'),
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  // Lặp lại bài hát
  void _toggleRepeat() {
    setState(() {
      if (loopMode == LoopMode.off) {
        loopMode = LoopMode.all;
        _player.setLoopMode(LoopMode.all);
      } else if (loopMode == LoopMode.all) {
        loopMode = LoopMode.one;
        _player.setLoopMode(LoopMode.one);
      } else {
        loopMode = LoopMode.off;
        _player.setLoopMode(LoopMode.off);
      }
    });
  }

  IconData _getRepeatIcon() {
    if (loopMode == LoopMode.one) return Icons.repeat_one_on_rounded;
    if (loopMode == LoopMode.all) return Icons.repeat_on_rounded;
    return Icons.repeat;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  // lib/pages/play_song.dart
  @override
  Widget build(BuildContext context) {
    final song = widget.playlist[currentIndex];
    final total = duration.inSeconds.toDouble();
    final current = position.inSeconds.toDouble();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_backgroundColor, AppColors.darkBackground],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Column(
            children: [
              Text(
                'ĐANG PHÁT',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              Text(
                'Danh sách bài hát',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.expand_more),
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              // Cho cái height của nd bằng height của màn hình đt
              height:
                  MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox.shrink(),
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          song['cover']!,
                          width: MediaQuery.of(context).size.width * 0.75,
                          height: MediaQuery.of(context).size.width * 0.75,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song['title']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song['artist']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 1.5, // Độ dày của thanh slider
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ), // Độ lớn của cục tròn trong slider
                          thumbColor: Colors.white,
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ), // Hiệu ứng khi nhấn hay kéo trên thanh sider giảm overlay có vòng tròn nó nhỏ hơn
                        ),
                        child: Slider(
                          inactiveColor: const Color.fromARGB(255,186,186,186,),
                          activeColor: Colors.white,
                          value: current,
                          max: total > 0 ? total : 1,
                          onChanged: (value) {
                            _player.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_format(position)),
                          Text(_format(duration)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              color: isShuffling
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                            onPressed: _toggleShuffle,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous, size: 36),
                            onPressed: _prevSong,
                          ),
                          IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              size: 72,
                            ),
                            onPressed: _togglePlay,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next, size: 36),
                            onPressed: _nextSong,
                          ),
                          IconButton(
                            icon: Icon(
                              _getRepeatIcon(),
                              color: loopMode != LoopMode.off
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                            onPressed: _toggleRepeat,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Cụm nút cuối trang
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.queue_music_outlined),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.share_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
