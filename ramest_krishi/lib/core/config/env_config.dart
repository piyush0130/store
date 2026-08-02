import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  static String get supabaseUrl {
    return dotenv.env['SUPABASE_URL'] ?? 'URL_NOT_FOUND';
  }

  static String get supabaseAnonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ?? 'KEY_NOT_FOUND';
  }
}
