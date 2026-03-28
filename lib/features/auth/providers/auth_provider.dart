import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  // Sign In
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  // Sign Up
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedFullName = fullName.trim();

    final existingProfiles = await _client
        .from('profiles')
        .select('id')
        .eq('username', normalizedUsername)
        .limit(1);

    if (existingProfiles.isNotEmpty) {
      throw 'That username is already taken.';
    }

    // 1. Create the user in Supabase Auth
    final response = await _client.auth.signUp(
      email: normalizedEmail,
      password: password,
      data: {
        'full_name': normalizedFullName,
        'username': normalizedUsername,
      },
    );

    // 2. Insert the user's details into the public 'profiles' table!
    final user = response.user;
    if (user != null) {
      await _client.from('profiles').insert({
        'id': user.id,
        'username': normalizedUsername,
        'full_name': normalizedFullName,
      });
    }

    return response.session != null;
  }

  // Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});
