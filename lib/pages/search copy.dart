import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm bài hát hoặc nghệ sĩ...',
              suffixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Gợi ý hôm nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('Hoài Lâm')),
              Chip(label: Text('Album 1')),
              Chip(label: Text('Đế Vương')),
            ],
          ),
        ],
      ),
    );
  }
}
