// lib/pages/search.dart
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';
import 'package:buzzify/blocs/data/data_bloc.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:buzzify/pages/albums.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allData = [];

  @override
  void initState() {
    super.initState();
    // Lấy dữ liệu ban đầu từ DataBloc nếu đã có
    final currentState = context.read<DataBloc>().state;
    if (currentState is DataLoaded) {
      _allData = [...currentState.songs, ...currentState.albums];
    }
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _searchResults = _allData.where((item) {
        final title = item['title']?.toLowerCase() ?? '';
        final artist = item['artists']?['name']?.toLowerCase() ?? '';
        return title.contains(query) || artist.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Tìm kiếm"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<DataBloc, DataState>(
        listener: (context, state) {
          if (state is DataLoaded) {
            setState(() {
              _allData = [...state.songs, ...state.albums];
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Bạn muốn nghe gì?',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => _searchController.clear())
                      : null,
                  fillColor: AppColors.darkGrey,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _searchResults.isEmpty && _searchController.text.isNotEmpty
                    ? const Center(child: Text('Không tìm thấy kết quả.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          final isSongItem = item.containsKey('duration_seconds');
                          final imageUrl = Supabase.instance.client.storage.from('Buzzify').getPublicUrl(item['cover_url']);

                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(isSongItem ? 4.0 : 8.0),
                              child: CachedNetworkImage(imageUrl: imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                            ),
                            title: Text(item['title'] ?? 'Không có tiêu đề'),
                            subtitle: Text(
                              isSongItem
                                ? 'Bài hát • ${item['artists']?['name'] ?? 'Không rõ'}'
                                : 'Album • ${item['artists']?['name'] ?? 'Không rõ'}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              if (isSongItem) {
                                final allSongs = (context.read<DataBloc>().state as DataLoaded).songs;
                                final originalIndex = allSongs.indexWhere((s) => s['id'] == item['id']);
                                if (originalIndex != -1) {
                                  context.read<AudioPlayerBloc>().add(
                                    StartPlaying(playlist: allSongs, index: originalIndex),
                                  );
                                }
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => AlbumPage(album: item)),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}