import 'package:flutter/material.dart';
import 'package:buzzify/common/app_colors.dart';
import 'package:buzzify/pages/splash.dart';
import 'package:buzzify/supabase/supabase_connect.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buzzify/blocs/data/data_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:buzzify/blocs/audio_player/audio_player_bloc.dart';


Future<void> main() async {
  // Khởi tạo Supabase
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
    // THAY ĐỔI Ở ĐÂY: Dùng MultiBlocProvider để cung cấp nhiều BLoC
    return MultiBlocProvider(
      providers: [
        // Provider cho trình phát nhạc
        BlocProvider(
          create: (context) => AudioPlayerBloc(),
        ),
        // Provider cho dữ liệu (và kích hoạt tải dữ liệu ngay lập tức)
        BlocProvider(
          create: (context) => DataBloc()..add(FetchDataRequested()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Buzzify",
        theme: ThemeData.dark(),
        home: const SplashPage(),
      ),
    );
  }
}
