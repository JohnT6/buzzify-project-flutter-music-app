// lib/main.dart
import 'package:flutter/material.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/pages/splash.dart';
import 'package:buzzify/supabase/supabase_connect.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buzzify/blocs/data/data_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';

// Import các service mới
import 'package:buzzify/services/api_client.dart';
import 'package:buzzify/services/api_song_service.dart';
import 'package:buzzify/services/api_album_service.dart';
import 'package:buzzify/services/api_artist_service.dart'; // <-- THÊM MỚI
import 'package:buzzify/services/api_playlist_service.dart'; // <-- THÊM MỚI
import 'package:buzzify/services/api_search_service.dart';

// --- THÊM 2 DÒNG NÀY ---
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:buzzify/services/api_auth_service.dart';

Future<void> main() async {
  // Khởi tạo Supabase (vẫn cần cho Auth)
  await initSupabase();
  
  // Thiết lập nơi lưu trữ cho Hydrated BLoC
  final storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );
  HydratedBloc.storage = storage;
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dùng MultiRepositoryProvider để cung cấp các service
    return MultiRepositoryProvider(
      providers: [
        // Cung cấp 1 ApiClient duy nhất cho toàn app
        RepositoryProvider<ApiClient>(
          create: (context) => ApiClient(),
        ),

        // --- THÊM 2 PROVIDER NÀY ---
        // 2. Cung cấp package lưu trữ an toàn
        RepositoryProvider<FlutterSecureStorage>(
          create: (context) => const FlutterSecureStorage(),
        ),
        // 3. Cung cấp ApiAuthService
        RepositoryProvider<ApiAuthService>(
          create: (context) => ApiAuthService(
            context.read<ApiClient>(),
            context.read<FlutterSecureStorage>(),
          ),
        ),

        // Cung cấp ApiSongService, nó sẽ tự lấy ApiClient
        RepositoryProvider<ApiSongService>(
          create: (context) => ApiSongService(
            context.read<ApiClient>(),
          ),
        ),
        // Cung cấp ApiAlbumService
        RepositoryProvider<ApiAlbumService>(
          create: (context) => ApiAlbumService(
            context.read<ApiClient>(),
          ),
        ),

        // --- THÊM 2 DỊCH VỤ MỚI ---
        // 4. "Cục sạc" nghệ sĩ
        RepositoryProvider<ApiArtistService>(
          create: (context) => ApiArtistService(
            context.read<ApiClient>(),
          ),
        ),
        // 5. "Cục sạc" playlist
        RepositoryProvider<ApiPlaylistService>(
          create: (context) => ApiPlaylistService(
            context.read<ApiClient>(),
          ),
        ),

        RepositoryProvider<ApiSearchService>(
          create: (context) => ApiSearchService(
            context.read<ApiClient>(),
          ),
        ),
      ],
      
      // MultiBlocProvider sẽ nằm bên trong
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AudioPlayerBloc(),
          ),
          // Sửa DataBloc để nó nhận các service
          BlocProvider(
            create: (context) => DataBloc(
              // Lấy service đã được cung cấp ở trên
              songService: context.read<ApiSongService>(),
              albumService: context.read<ApiAlbumService>(),
              artistService: context.read<ApiArtistService>(),
              playlistService: context.read<ApiPlaylistService>(),
            )..add(FetchDataRequested()), // Kích hoạt tải dữ liệu
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Buzzify",
          theme: ThemeData.dark(),
          home: const SplashPage(),
        ),
      ),
    );
  }
}