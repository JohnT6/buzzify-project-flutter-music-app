import 'dart:ui';
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buzzify/common/formatters.dart';

class PlaySongPage extends StatefulWidget {
  const PlaySongPage({super.key});

  @override
  State<PlaySongPage> createState() => _PlaySongPageState();
}

String _format(Duration d) {
  final m = d.inMinutes.remainder(60).toString();
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

class _PlaySongPageState extends State<PlaySongPage> {
  Color _backgroundColor = AppColors.darkBackground;

  @override
  void initState() {
    super.initState();
    final currentState = context.read<AudioPlayerBloc>().state;
    _updateBackgroundColor(currentState.currentSong?['cover_url']);
  }

  Future<void> _updateBackgroundColor(String? coverUrl) async {
    if (coverUrl == null || !mounted) return;
    final publicUrl = Supabase.instance.client.storage
        .from('Buzzify')
        .getPublicUrl(coverUrl);
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(publicUrl),
      );
      if (mounted) {
        setState(
          () => _backgroundColor =
              palette.vibrantColor?.color ?? AppColors.darkBackground,
        );
      }
    } catch (e) {
      // Bỏ qua lỗi nếu không tải được ảnh để lấy màu
    }
  }

  IconData _getRepeatIcon(LoopMode loopMode) {
    if (loopMode == LoopMode.one) return Icons.repeat_one;
    return Icons.repeat;
  }

  void _showLyricsDialog(BuildContext pageContext) {
    final audioBloc = pageContext.read<AudioPlayerBloc>();
    // Gửi event yêu cầu tải lyrics nếu chưa có hoặc bị lỗi
    if (audioBloc.state.lyricsStatus == LyricsStatus.initial ||
        audioBloc.state.lyricsStatus == LyricsStatus.failure) {
      audioBloc.add(FetchLyricsRequested());
    }

    showModalBottomSheet(
      context: pageContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) {
        // Cung cấp lại BLoC cho modal để nó có thể lắng nghe
        return BlocProvider.value(
          value: audioBloc,
          child: const LyricsSheetContent(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioPlayerBloc, AudioPlayerState>(
      listenWhen: (prev, current) => prev.currentIndex != current.currentIndex,
      listener: (context, state) =>
          _updateBackgroundColor(state.currentSong?['cover_url']),
      builder: (context, state) {
        final song = state.currentSong;
        if (song == null) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: const Center(child: Text("Chọn một bài hát")),
          );
        }

        final imageUrl = Supabase.instance.client.storage
            .from('Buzzify')
            .getPublicUrl(song['cover_url'] ?? '');

        return Container(
          // <-- THÊM LẠI CONTAINER VỚI GRADIENT
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_backgroundColor, AppColors.darkBackground],
            ),
          ),
          child: Scaffold(
            backgroundColor:
                Colors.transparent, // <-- Nền trong suốt để gradient hiển thị
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.expand_more),
              ),
              title: const Column(
                children: [
                  Text(
                    'ĐANG PHÁT TỪ',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    'Danh sách bài hát',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      fit: BoxFit.cover,
                      // Widget hiển thị trong lúc chờ tải ảnh (giúp UI mượt hơn)
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[850]),
                      // Widget hiển thị khi có lỗi tải ảnh
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsetsGeometry.fromLTRB(12, 0, 0, 0),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song['title'] ?? 'Không có tiêu đề',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              buildArtistString(song),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.add_circle_outline, size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 1.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      thumbColor: Colors.white,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12.0,
                      ),
                    ),
                    child: Slider(
                      value: state.position.inSeconds.toDouble().clamp(
                        0.0,
                        state.totalDuration.inSeconds.toDouble(),
                      ),
                      max: state.totalDuration.inSeconds.toDouble() > 0
                          ? state.totalDuration.inSeconds.toDouble()
                          : 1.0,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white.withValues(alpha: 0.3),
                      onChanged: (value) => context.read<AudioPlayerBloc>().add(
                        SeekToPosition(Duration(seconds: value.toInt())),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_format(state.position)),
                        Text(_format(state.totalDuration)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: state.isShuffling
                              ? AppColors.primary
                              : Colors.white,
                        ),
                        onPressed: () => context.read<AudioPlayerBloc>().add(
                          ToggleShuffleRequested(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 40),
                        onPressed: () => context.read<AudioPlayerBloc>().add(
                          PreviousSongRequested(),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            state.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 45,
                            color: AppColors.darkGrey,
                          ),
                          onPressed: () => context.read<AudioPlayerBloc>().add(
                            state.isPlaying
                                ? PauseRequested()
                                : PlayRequested(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 40),
                        onPressed: () => context.read<AudioPlayerBloc>().add(
                          NextSongRequested(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _getRepeatIcon(state.loopMode),
                          color: state.loopMode != LoopMode.off
                              ? AppColors.primary
                              : Colors.white,
                        ),
                        onPressed: () => context.read<AudioPlayerBloc>().add(
                          ToggleRepeatRequested(),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => _showLyricsDialog(context),
                        icon: const Icon(Icons.lyrics_outlined),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.share_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =======================================================================
// WIDGET RIÊNG CHO NỘI DUNG CỦA MODAL LYRICS
// =======================================================================
class LyricsSheetContent extends StatelessWidget {
  const LyricsSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    // ScrollController chỉ cần tạo ở đây
    final ItemScrollController itemScrollController = ItemScrollController();
    // Hàm _format giờ là hàm toàn cục, có thể gọi trực tiếp
    String format(Duration d) => _format(d);

    return BlocConsumer<AudioPlayerBloc, AudioPlayerState>(
      listenWhen: (p, c) => p.currentLyricIndex != c.currentLyricIndex,
      listener: (context, state) {
        if (state.currentLyricIndex != -1 && itemScrollController.isAttached) {
          itemScrollController.scrollTo(
            index: state.currentLyricIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            alignment: 0.3,
          );
        }
      },
      builder: (context, state) {
        final song = state
            .currentSong!; // Chắc chắn có song vì modal chỉ mở từ PlaySongPage
        return Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: Supabase.instance.client.storage
                  .from('Buzzify')
                  .getPublicUrl(song['cover_url'] ?? ''),
              fit: BoxFit.cover,
              // Widget hiển thị trong lúc chờ tải ảnh (giúp UI mượt hơn)
              placeholder: (context, url) => Container(color: Colors.grey[850]),
              // Widget hiển thị khi có lỗi tải ảnh
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: IconButton(
                            icon: const Icon(
                              Icons.expand_more,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                song['title'] ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song['artists']?['name'] ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48.0),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          switch (state.lyricsStatus) {
                            case LyricsStatus.loading:
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            case LyricsStatus.failure:
                            case LyricsStatus
                                .initial: // Hiển thị lỗi cho cả trạng thái initial nếu lyrics rỗng
                              return const Center(
                                child: Text(
                                  'Không tìm thấy lời bài hát.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              );
                            case LyricsStatus.loaded:
                              return ScrollablePositionedList.builder(
                                itemCount: state.lyrics.length,
                                itemScrollController: itemScrollController,
                                itemBuilder: (context, index) {
                                  final line = state.lyrics[index];
                                  final isCurrent =
                                      index == state.currentLyricIndex;
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
                                            : Colors.white.withAlpha(150),
                                        fontSize: isCurrent ? 28 : 26,
                                        fontWeight: FontWeight.bold,
                                        height: 1.6,
                                      ),
                                    ),
                                  );
                                },
                              );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 1.5,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            thumbColor: Colors.white,
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12.0,
                            ),
                          ),
                          child: Slider(
                            value: state.position.inSeconds.toDouble().clamp(
                              0.0,
                              state.totalDuration.inSeconds.toDouble(),
                            ),
                            max: state.totalDuration.inSeconds.toDouble() > 0
                                ? state.totalDuration.inSeconds.toDouble()
                                : 1.0,
                            activeColor: Colors.white,
                            inactiveColor: Colors.white.withValues(alpha: 0.3),
                            onChanged: (value) =>
                                context.read<AudioPlayerBloc>().add(
                                  SeekToPosition(
                                    Duration(seconds: value.toInt()),
                                  ),
                                ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                format(state.position),
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                format(state.totalDuration),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: Icon(
                            state.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 64,
                            color: Colors.white,
                          ),
                          onPressed: () => context.read<AudioPlayerBloc>().add(
                            state.isPlaying
                                ? PauseRequested()
                                : PlayRequested(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
