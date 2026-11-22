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

  Future<void> signOut();
}

/// Implementasi demo lokal; kredensial ini bukan akun produksi.
class DemoAuthRepository implements AuthRepository {
  @override
  Future<void> resetPassword(String email) async {
    throw Exception('Reset kata sandi hanya tersedia untuk akun Supabase.');
  }

  @override
  Future<AppUser?> restoreSession() async => null;

  @override
  Future<AppUser> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final normalized = email.trim().toLowerCase();

    if (normalized == 'admin@tinggalklik.id' && password == 'admin123') {
      return AppUser(
          id: 'admin-001',
          name: 'Administrator',
          email: normalized,
          role: UserRole.admin);
    }
    if (normalized == 'owner@demo.id' && password == 'owner123') {
      return AppUser(
          id: 'owner-001',
          name: 'Pemilik Demo',
          email: normalized,
          role: UserRole.kosOwner,
          ownerVerified: true);
    }
    if (normalized == 'pelanggan@demo.id' && password == 'user123') {
      return AppUser(
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
    return AppUser(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        email: email.trim().toLowerCase(),
        role: role,
        ownerVerified: false);
  }

  @override
  Future<void> signOut() async {}
}
