import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  static final _auth = SupabaseService.client.auth;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final res = await _auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'phone': phone, 'role': 'customer'},
    );
    if (res.user != null) {
      await SupabaseService.client.from('profiles').insert({
        'id': res.user!.id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'customer',
      });
    }
    return res;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) => _auth.signInWithPassword(email: email, password: password);

  static Future<void> signOut() => _auth.signOut();

  static Future<void> resetPassword(String email) =>
      _auth.resetPasswordForEmail(email);

  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
}

