import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );

      if (res.user != null) {
        try {
          // Check if profile exists first
          final existingProfile = await supabase
              .from('profiles')
              .select()
              .eq('id', res.user!.id)
              .single();

          if (existingProfile == null) {
            // Only insert if profile doesn't exist
            await supabase.from('profiles').insert({
              'id': res.user!.id,
              'full_name': fullName,
              'email': email,
              'role': role,
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          // If error is not about duplicate key, create the profile
          if (!e.toString().contains('23505')) {
            await supabase.from('profiles').insert({
              'id': res.user!.id,
              'full_name': fullName,
              'email': email,
              'role': role,
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }

      return res;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    supabase.auth.signOut();
  }

  Session? getSession() {
    return supabase.auth.currentSession;
  }
}
