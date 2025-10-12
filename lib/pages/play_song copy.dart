import 'package:buzzify/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';

class PlaySongPage extends StatefulWidget {
  final List<Map<String, dynamic>> playlist;
  final String albumCover;
  final String albumTitle;

  const PlaySongPage({
    required this.playlist,
    required this.albumCover,
    required this.albumTitle,
    super.key,
  });

  @override
  State<PlaySongPage> createState() => _PlaySongPageState();
}

class _PlaySongPageState extends State<PlaySongPage> {
  // Biến để lưu màu nền, đặt màu mặc định ban đầu
  Color _backgroundColor = AppColors.darkBackground;

  late AudioPlayer _player;
  int currentIndex = 0;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadSong();
    _player.positionStream.listen((pos) => setState(() => position = pos));
    _player.durationStream.listen((dur) {
      if (dur != null) setState(() => duration = dur);
    });
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _nextSong();
      }
    });
  }

  // Hàm để cập nhật màu nền từ ảnh
  Future<void> _updateBackgroundColor() async {
    final imageProvider = AssetImage(widget.playlist[currentIndex]['cover']!);
    final palette = await PaletteGenerator.fromImageProvider(imageProvider);

    // Lấy màu chủ đạo hoặc một màu mặc định nếu không tìm thấy
    setState(() {
      // Lấy màu sống động nhất
      _backgroundColor =
          palette.vibrantColor?.color ??
          AppColors.darkBackground; // Màu mặc định cuối cùng
    });
  }

  Future<void> _loadSong() async {
    // Cập nhật màu nền mỗi khi load bài hát mới
    await _updateBackgroundColor();
    final song = widget.playlist[currentIndex];
    await _player.setAsset(song['file']!);
    await _player.play();
    setState(() => isPlaying = true);
  }

  void _togglePlay() async {
    if (isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
    setState(() => isPlaying = !isPlaying);
  }

  void _nextSong() {
    if (currentIndex < widget.playlist.length - 1) {
      currentIndex++;
      _loadSong();
    }
  }

  void _prevSong() {
    if (currentIndex > 0) {
      currentIndex--;
      _loadSong();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.playlist[currentIndex];
    final total = duration.inSeconds.toDouble();
    final current = position.inSeconds.toDouble();

    return Stack(
      children: [
        //   Image.asset(
        //                 widget.albumCover,
        //                width: double.infinity,
        //                height: double.infinity,
        //                fit: BoxFit.cover,),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,

              colors: [
                _backgroundColor,
                // Colors.black,
                AppColors.darkBackground,
              ],
              // Chọn điểm dừng giữa các màu
              // stops: const [0.0, 2.5],
            ),
          ),
        ),

        // Nội dung chính
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Phát nhạc',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    widget.albumCover,
                    width: 330,
                    height: 330,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  song['title']!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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
                    inactiveColor: const Color.fromARGB(255, 186, 186, 186),
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
                  children: [Text(_format(position)), Text(_format(duration))],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: _prevSong,
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause_circle : Icons.play_circle,
                        size: 48,
                      ),
                      onPressed: _togglePlay,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: _nextSong,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
