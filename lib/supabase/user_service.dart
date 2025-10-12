import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  static final user = Supabase.instance.client;

  static User? getCurrentUser() {
    return user.auth.currentUser;
  }
}