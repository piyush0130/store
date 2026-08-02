import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupabaseService {
  static Future<void> initialize() async {
    // In production, these should be loaded from .env file
    const supabaseUrl = 'https://YOUR_SUPABASE_URL.supabase.co';
    const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

// Riverpod Provider for easy access across the app's repositories
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});
