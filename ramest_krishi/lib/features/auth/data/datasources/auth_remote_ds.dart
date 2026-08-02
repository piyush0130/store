import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSource(this.client);

  Future<Map<String, dynamic>> login(String phone, String password) async {
    // Note: Supabase supports phone auth, assuming email here for standard setup, 
    // but you would adapt this based on actual Supabase config.
    final response = await client.auth.signInWithPassword(
      phone: phone, // Assuming phone was mapped in Supabase, else use email
      password: password,
    );

    if (response.user == null) {
      throw Exception('Login failed');
    }

    // Fetch the profile from the custom profiles table
    final profileData = await client
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();

    return profileData;
  }

  Future<void> logout() async {
    await client.auth.signOut();
  }

  bool get isSessionValid => client.auth.currentSession != null && !client.auth.currentSession!.isExpired;
}
