import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:buzzify/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
// import 'package:marquee/marquee.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

// Lớp để chứa dữ liệu một dòng lyric đã được phân tích
class LyricLine {
  final Duration timestamp;
  final String text;
  LyricLine(this.timestamp, this.text);
}

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
  // Biến state cho giao diện và player
  Color _backgroundColor = AppColors.darkBackground;
  late AudioPlayer _player;
  late int currentIndex;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isShuffling = false;
  LoopMode loopMode = LoopMode.off;

  // Các biến state cho lyrics đồng bộ
  List<LyricLine> _syncedLyrics = [];
  String? _lyricsError;
  bool _isFetchingLyrics = false;
  int _currentLyricIndex = -1;
  final ItemScrollController _itemScrollController = ItemScrollController();
  StreamSubscription<Duration>? _positionSubscription;
  final Duration _lyricSyncOffset = const Duration(milliseconds: 500);

  // Biến để theo dõi xem lyrics đang hiển thị cho bài hát nào
  int _lyricsForIndex = -1;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    currentIndex = widget.initialIndex;
    _loadSong();

    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        isPlaying = state.playing;
      });
      if (state.processingState == ProcessingState.completed) {
        _nextSong();
      }
    });
    _player.loopModeStream.listen(
      (mode) => mounted ? setState(() => loopMode = mode) : null,
    );
    _player.shuffleModeEnabledStream.listen(
      (enabled) => mounted ? setState(() => isShuffling = enabled) : null,
    );
    _player.positionStream.listen(
      (pos) => mounted ? setState(() => position = pos) : null,
    );
    _player.durationStream.listen((dur) {
      if (dur != null && mounted) setState(() => duration = dur);
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _updateBackgroundColor() async {
    final imageProvider = AssetImage(widget.playlist[currentIndex]['cover']!);
    final palette = await PaletteGenerator.fromImageProvider(imageProvider);
    if (mounted) {
      setState(() {
        _backgroundColor =
            palette.vibrantColor?.color ?? AppColors.darkBackground;
      });
    }
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
      if (mounted) {
        setState(() {
          currentIndex++;
        });
      }
      _loadSong();
    } else if (loopMode != LoopMode.all) {
      _player.stop();
    }
  }

  void _prevSong() {
    if (currentIndex > 0) {
      if (mounted) {
        setState(() {
          currentIndex--;
        });
      }
      _loadSong();
    }
  }

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

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  List<LyricLine> _parseLrc(String lrcString) {
    final List<LyricLine> lines = [];
    final RegExp regExp = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lrcString.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          lines.add(
            LyricLine(
              Duration(minutes: min, seconds: sec, milliseconds: ms),
              text,
            ),
          );
        }
      }
    }
    return lines;
  }

  Future<void> _fetchLyrics(StateSetter setModalState, int songIndex) async {
    setModalState(() {
      _isFetchingLyrics = true;
      _syncedLyrics = [];
      _lyricsError = null;
      _lyricsForIndex = songIndex;
    });

    try {
      final song = widget.playlist[songIndex];
      final artistName = Uri.encodeComponent(song['artist']!);
      final trackName = Uri.encodeComponent(song['title']!);
      final url = Uri.parse(
        'https://lrclib.net/api/get?artist_name=$artistName&track_name=$trackName',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final syncedLyrics = data['syncedLyrics'];

        if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
          setModalState(() {
            _syncedLyrics = _parseLrc(syncedLyrics);
          });
        } else {
          setModalState(() {
            _lyricsError = 'Không tìm thấy lời cho bài hát này.';
          });
        }
      } else {
        setModalState(() {
          _lyricsError =
              'Không thể tải lời bài hát (Lỗi ${response.statusCode}).';
        });
      }
    } catch (e) {
      setModalState(() {
        _lyricsError = 'Lỗi kết nối mạng. Vui lòng kiểm tra lại.';
      });
    } finally {
      setModalState(() {
        _isFetchingLyrics = false;
      });
    }
  }

  void _startLyricSync(StateSetter setModalState) {
    _positionSubscription?.cancel();
    _positionSubscription = _player.positionStream.listen((position) {
      if (_syncedLyrics.isEmpty || !mounted) return;

      final adjustedPosition = position - _lyricSyncOffset;
      int newIndex = _syncedLyrics.lastIndexWhere(
        (line) => adjustedPosition >= line.timestamp,
      );

      if (newIndex != _currentLyricIndex) {
        setModalState(() {
          _currentLyricIndex = newIndex;
        });
        if (newIndex != -1 && _itemScrollController.isAttached) {
          _itemScrollController.scrollTo(
            index: newIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            alignment: 0.3,
          );
        }
      }
    });
  }

  void _showLyricsDialog() {
    _positionSubscription?.cancel();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            if (currentIndex != _lyricsForIndex && !_isFetchingLyrics) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchLyrics(setModalState, currentIndex).then((_) {
                  _startLyricSync(setModalState);
                });
              });
            } else if (_syncedLyrics.isNotEmpty &&
                (_positionSubscription == null ||
                    (_positionSubscription?.isPaused ?? true))) {
              _startLyricSync(setModalState);
            }

            return WillPopScope(
              onWillPop: () async {
                _positionSubscription?.pause();
                return true;
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.playlist[currentIndex]['cover']!,
                    fit: BoxFit.cover,
                  ),
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                      child: Container(color: Colors.black.withOpacity(0.5)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 1. Icon bên trái
                                SizedBox(
                                  width: 48.0,
                                  child: IconButton(
                                    icon: const Icon(Icons.expand_more, color: Colors.white),
                                    onPressed: () {
                                      _positionSubscription?.pause();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                                // 2. Title và Artist ở giữa
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.playlist[currentIndex]['title'] ?? 'Không có tiêu đề',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.playlist[currentIndex]['artist'] ?? 'Không rõ nghệ sĩ',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // 3. Widget giữ chỗ bên phải để căn giữa title
                                const SizedBox(width: 48.0),
                              ],
                            ),
                        // const Divider(color: Colors.white54, height: 32),
                        Expanded(
                          child: _isFetchingLyrics
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : _syncedLyrics.isEmpty
                              ? Center(
                                  child: Text(
                                    _lyricsError ?? 'Không có lời bài hát.',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                )
                              : ScrollablePositionedList.builder(
                                  itemCount: _syncedLyrics.length,
                                  itemScrollController: _itemScrollController,
                                  itemBuilder: (context, index) {
                                    final line = _syncedLyrics[index];
                                    final isCurrent =
                                        index == _currentLyricIndex;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16.0,
                                      ),
                                      child: Text(
                                        line.text,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isCurrent
                                              ? Colors.white
                                              : Colors.white.withValues(alpha: 0.5),
                                          fontSize: isCurrent ? 28 : 26,
                                          fontWeight: FontWeight.bold,
                                          height: 1.6,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<Duration>(
                          stream: _player.positionStream,
                          builder: (context, snapshot) {
                            final currentPos = snapshot.data ?? Duration.zero;
                            final totalDur = _player.duration ?? Duration.zero;
                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 1.5,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 5,
                                    ),
                                    thumbColor: Colors.white,
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12,
                                    ),
                                  ),
                                  child: Slider(
                                    value: currentPos.inSeconds
                                        .toDouble()
                                        .clamp(
                                          0.0,
                                          totalDur.inSeconds.toDouble(),
                                        ),
                                    max: totalDur.inSeconds.toDouble() > 0
                                        ? totalDur.inSeconds.toDouble()
                                        : 1.0,
                                    inactiveColor: Colors.white.withValues(
                                      alpha:  0.3,
                                    ),
                                    activeColor: Colors.white,
                                    onChanged: (value) {
                                      _player.seek(
                                        Duration(seconds: value.toInt()),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _format(currentPos),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        _format(totalDur),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<PlayerState>(
                          stream: _player.playerStateStream,
                          builder: (context, snapshot) {
                            final isPlayingNow =
                                snapshot.data?.playing ?? false;
                            return IconButton(
                              icon: Icon(
                                isPlayingNow
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                size: 64,
                                color: Colors.white,
                              ),
                              onPressed: _togglePlay,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.playlist[currentIndex];

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
              height:
                  MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
                          Padding(padding: EdgeInsetsGeometry.fromLTRB(12, 0, 0, 0)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // // Sử dụng SizedBox để giới hạn chiều cao cho Marquee
                                // SizedBox(
                                //   // width: 280,
                                //   height: 30, // Chiều cao cho dòng title
                                //   child: Marquee(
                                //     text: song['title']!,
                                //     style: const TextStyle(
                                //       fontSize: 24,
                                //       fontWeight: FontWeight.bold,
                                //     ),
                                //     scrollAxis: Axis.horizontal,
                                //     crossAxisAlignment: CrossAxisAlignment.start,
                                //     blankSpace: 20.0,
                                //     velocity: 50.0, // Tốc độ chạy chữ
                                //     pauseAfterRound: const Duration(seconds: 2),
                                //   ),
                                // ),
                                // const SizedBox(height: 4),
                                // SizedBox(
                                //   // width: 280,
                                //   height: 20, // Chiều cao cho dòng artist
                                //   child: Marquee(
                                //     text: song['artist']!,
                                //     style: TextStyle(
                                //       fontSize: 16,
                                //       color: Colors.white.withOpacity(0.7),
                                //     ),
                                //     scrollAxis: Axis.horizontal,
                                //     crossAxisAlignment: CrossAxisAlignment.center,
                                //     blankSpace: 20.0,
                                //     velocity: 40.0,
                                //     pauseAfterRound: const Duration(seconds: 2),
                                //   ),
                                // ),
                                Text(song['title']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text(song['artist']!, style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.8))),
                              ],
                            ),
                          ),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline)),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      StreamBuilder<Duration>(
                        stream: _player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = _player.duration ?? Duration.zero;
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 1.5,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 5,
                                  ),
                                  thumbColor: Colors.white,
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                ),
                                child: Slider(
                                  value: position.inSeconds.toDouble().clamp(
                                    0.0,
                                    duration.inSeconds.toDouble(),
                                  ),
                                  max: duration.inSeconds.toDouble() > 0
                                      ? duration.inSeconds.toDouble()
                                      : 1.0,
                                  inactiveColor: const Color.fromARGB(
                                    255,
                                    186,
                                    186,
                                    186,
                                  ),
                                  activeColor: Colors.white,
                                  onChanged: (value) {
                                    _player.seek(
                                      Duration(seconds: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_format(position)),
                                    Text(_format(duration)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _showLyricsDialog,
                        icon: const Icon(Icons.lyrics_outlined),
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
}
