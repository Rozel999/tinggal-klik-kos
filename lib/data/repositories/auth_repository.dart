import 'dart:async';

import '../../domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signIn(String email, String password);
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });
  Future<AppUser?> restoreSession() async => null;
  Future<void> resetPassword(String email) async {
    throw Exception('Reset kata sandi tidak didukung oleh penyedia akun ini.');
  }

  Future<AppUser> updateDisplayName(String name) async {
    throw Exception('Perubahan profil tidak didukung oleh penyedia akun ini.');
  }

  Future<void> signInWithGoogle() async {
    throw Exception('Login Google tidak didukung oleh penyedia akun ini.');
  }

  Stream<AppUser?> get authStateChanges => const Stream.empty();

  Future<void> signOut();
}

/// Implementasi demo lokal; kredensial ini bukan akun produksi.
class DemoAuthRepository implements AuthRepository {
  AppUser? _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();
  @override
  Future<void> resetPassword(String email) async {
    throw Exception('Reset kata sandi hanya tersedia untuk akun Supabase.');
  }

  @override
  Future<AppUser> updateDisplayName(String name) async {
    final current = _currentUser;
    if (current == null) throw Exception('Sesi login sudah berakhir.');
    _currentUser = AppUser(
      id: current.id,
      name: name.trim(),
      email: current.email,
      role: current.role,
      ownerVerified: current.ownerVerified,
    );
    return _currentUser!;
  }

  @override
  Future<void> signInWithGoogle() async {
    throw Exception('Login Google hanya tersedia melalui Supabase.');
  }

  @override
  Future<AppUser?> restoreSession() async => null;

  @override
  Future<AppUser> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final normalized = email.trim().toLowerCase();

    if (normalized == 'admin@tinggalklik.id' && password == 'admin123') {
      return _currentUser = AppUser(
          id: 'admin-001',
          name: 'Administrator',
          email: normalized,
          role: UserRole.admin);
    }
    if (normalized == 'owner@demo.id' && password == 'owner123') {
      return _currentUser = AppUser(
          id: 'owner-001',
          name: 'Pemilik Demo',
          email: normalized,
          role: UserRole.kosOwner,
          ownerVerified: true);
    }
    if (normalized == 'pelanggan@demo.id' && password == 'user123') {
      return _currentUser = AppUser(
          id: 'customer-001',
          name: 'Pelanggan Demo',
          email: normalized,
          role: UserRole.customer);
    }
    throw Exception('Email atau kata sandi demo tidak sesuai.');
  }

  @override
  Future<AppUser> register(
      {required String name,
      required String email,
      required String password,
      required UserRole role}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (role == UserRole.admin) {
      throw Exception('Role Admin hanya dapat diberikan melalui backend.');
    }
    return _currentUser = AppUser(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        email: email.trim().toLowerCase(),
        role: role,
        ownerVerified: false);
  }

  @override
  Future<void> signOut() async => _currentUser = null;
}
