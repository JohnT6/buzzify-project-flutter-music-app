import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/widgets.dart';

Future<void> initSupabase() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://koyoiapqhksuwgrzjvvl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtveW9pYXBxaGtzdXdncnpqdnZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNzk0ODgsImV4cCI6MjA3Mzk1NTQ4OH0.XutEkh4En3v81OcunBh2AHxdg3h7xy_TGRFidkyuft0',
  );
}
