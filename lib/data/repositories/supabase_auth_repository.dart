import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<AppUser> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final authUser = response.user;
    if (authUser == null) {
      throw Exception('Login Supabase tidak mengembalikan akun.');
    }
    return _loadProfile(authUser);
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (role != UserRole.customer && role != UserRole.kosOwner) {
      throw Exception('Role ini tidak dapat dipilih saat mendaftar.');
    }
    final response = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {
        'display_name': name.trim(),
        'role': role == UserRole.kosOwner ? 'kos_owner' : 'customer',
      },
    );
    final authUser = response.user;
    if (authUser == null) throw Exception('Pendaftaran belum selesai.');
    if (response.session == null) {
      throw Exception(
          'Supabase masih mewajibkan konfirmasi email. Nonaktifkan Confirm email pada pengaturan Auth proyek agar akun bisa langsung masuk.');
    }
    return _loadProfile(authUser);
  }

  @override
  Future<AppUser?> restoreSession() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    try {
      return await _loadProfile(authUser);
    } catch (_) {
      await _client.auth.signOut();
      return null;
    }
  }

  Future<AppUser> _loadProfile(User authUser) async {
    final row = await _client
        .from('profiles')
        .select('id,email,display_name,role,owner_verified')
        .eq('id', authUser.id)
        .single();
    final role = switch (row['role'] as String) {
      'app_owner' => UserRole.admin,
      'admin' => UserRole.admin,
      'kos_owner' => UserRole.kosOwner,
      _ => UserRole.customer,
    };
    return AppUser(
      id: authUser.id,
      name: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? row['display_name'] as String
          : authUser.email ?? 'Pengguna',
      email: (row['email'] as String?) ?? authUser.email ?? '',
      role: role,
      ownerVerified: row['owner_verified'] as bool? ?? false,
    );
  }

  @override
  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email.trim().toLowerCase());

  @override
  Future<void> signOut() => _client.auth.signOut();
}
