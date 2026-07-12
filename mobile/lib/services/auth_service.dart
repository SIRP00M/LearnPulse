import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class AuthService {
  SupabaseClient get _supabase => Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Session? get currentSession => _supabase.auth.currentSession;

  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) {
    return _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim(), 'role': role},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() {
    return _supabase.auth.signOut();
  }

  Future<UserProfile?> getMyProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return UserProfile.fromMap(data);
  }
}
