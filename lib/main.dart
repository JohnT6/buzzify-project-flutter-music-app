// lib/main.dart
import 'package:flutter/material.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/pages/splash.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buzzify/blocs/data/data_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';

// Import các service
import 'package:buzzify/services/api_client.dart';
import 'package:buzzify/services/api_song_service.dart';
import 'package:buzzify/services/api_album_service.dart';
import 'package:buzzify/services/api_artist_service.dart';
import 'package:buzzify/services/api_playlist_service.dart';
import 'package:buzzify/services/api_search_service.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:buzzify/services/api_auth_service.dart';
import 'package:buzzify/blocs/auth/auth_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    // Dùng MultiRepositoryProvider để cung cấp các service (Dependency Injection)
    return MultiRepositoryProvider(
      providers: [
        // 1. Cung cấp ApiClient (Dùng chung cho toàn app)
        RepositoryProvider<ApiClient>(
          create: (context) => ApiClient(),
        ),

        // 2. Cung cấp FlutterSecureStorage (Lưu token)
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

        // 4. Cung cấp ApiSongService
        RepositoryProvider<ApiSongService>(
          create: (context) => ApiSongService(
            context.read<ApiClient>(),
          ),
        ),

        // 5. Cung cấp ApiAlbumService
        RepositoryProvider<ApiAlbumService>(
          create: (context) => ApiAlbumService(
            context.read<ApiClient>(),
          ),
        ),

        // 6. Cung cấp ApiArtistService
        RepositoryProvider<ApiArtistService>(
          create: (context) => ApiArtistService(
            context.read<ApiClient>(),
          ),
        ),

        // 7. Cung cấp ApiPlaylistService
        RepositoryProvider<ApiPlaylistService>(
          create: (context) => ApiPlaylistService(
            context.read<ApiClient>(),
          ),
        ),

        // 8. Cung cấp ApiSearchService
        RepositoryProvider<ApiSearchService>(
          create: (context) => ApiSearchService(
            context.read<ApiClient>(),
          ),
        ),
      ],
      
      // MultiBlocProvider khởi tạo các BLoC
      child: MultiBlocProvider(
        providers: [
          // AuthBloc phải được khởi tạo trước để DataBloc có thể lấy userId
          BlocProvider(
            create: (context) => AuthBloc(
              apiAuthService: context.read<ApiAuthService>(),
            ),
          ),

          BlocProvider(
            create: (context) => AudioPlayerBloc(),
          ),

          // DataBloc: Lấy userId từ AuthBloc để tải danh sách yêu thích
          BlocProvider(
            create: (context) {
              // Lấy trạng thái đăng nhập hiện tại
              final authState = context.read<AuthBloc>().state;
              final userId = authState.user?.id;
              
              return DataBloc(
                songService: context.read<ApiSongService>(),
                albumService: context.read<ApiAlbumService>(),
                artistService: context.read<ApiArtistService>(),
                playlistService: context.read<ApiPlaylistService>(),
              )..add(FetchDataRequested(userId: userId)); // <-- Truyền userId vào đây
            },
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