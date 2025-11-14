// lib/widgets/music_visualizer.dart
import 'package:flutter/material.dart';
import 'package:buzzify/common/app_colors.dart';
import 'dart:math';
// import 'dart:async'; // (Không cần thiết)

class MusicVisualizer extends StatelessWidget {
  final bool isPlaying;
  const MusicVisualizer({super.key, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      // Tạo 3 thanh
      children: List.generate(3, (index) => 
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5), // Khoảng cách giữa các thanh
          child: VisualizerBar(
            // Gửi trạng thái isPlaying và làm trễ animation
            isPlaying: isPlaying,
            durationMilliseconds: (300 + (index * 100)), // 300ms, 400ms, 500ms
          ), 
        )
      ),
    );
  }
}

class VisualizerBar extends StatefulWidget {
  final bool isPlaying;
  final int durationMilliseconds;
  const VisualizerBar({
    super.key, 
    required this.isPlaying, 
    required this.durationMilliseconds
  });

  @override
  State<VisualizerBar> createState() => _VisualizerBarState();
}

class _VisualizerBarState extends State<VisualizerBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  double _currentHeight = 5.0; // Chiều cao cơ bản (trạng thái dừng)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMilliseconds),
    );
    
    if (widget.isPlaying) {
      _startAnimationLoop();
    }
  }

  @override
  void didUpdateWidget(VisualizerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimationLoop();
      } else {
        _stopAnimationLoop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- SỬA LỖI TẠI ĐÂY ---
  void _startAnimationLoop() {
    if (!mounted) return;
    
    final double targetHeight = 5.0 + (_random.nextDouble() * 15.0);
    
    // 1. Khai báo 'animation' trước
    late Animation<double> animation;
    
    // 2. Gán giá trị cho 'animation'
    animation = Tween<double>(
      begin: _currentHeight,
      end: targetHeight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
      ..addListener(() {
        if (mounted) {
          setState(() {
            // 3. Bây giờ 'animation.value' đã hợp lệ
            _currentHeight = animation.value; 
          });
        }
      });

    _controller
      ..reset()
      ..forward().whenComplete(() {
        if (widget.isPlaying && mounted) { // Thêm kiểm tra 'mounted'
          _startAnimationLoop();
        }
      });
  }

  // --- SỬA LỖI TƯƠNG TỰ TẠI ĐÂY ---
  void _stopAnimationLoop() {
    _controller.stop();
    
    // 1. Khai báo 'animation' trước
    late Animation<double> animation;
    
    // 2. Gán giá trị cho 'animation'
    animation = Tween<double>(
      begin: _currentHeight,
      end: 5.0, // Quay về 5.0
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut))
      ..addListener(() {
        if (mounted) {
          setState(() {
            // 3. Bây giờ 'animation.value' đã hợp lệ
            _currentHeight = animation.value;
          });
        }
      });
      
    _controller
      ..reset()
      ..animateTo(1.0, duration: const Duration(milliseconds: 150));
  }
  // --- KẾT THÚC SỬA LỖI ---

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4, // Độ rộng thanh
      height: _currentHeight, // Chiều cao động
      decoration: BoxDecoration(
        color: AppColors.primary, // Màu xanh
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}