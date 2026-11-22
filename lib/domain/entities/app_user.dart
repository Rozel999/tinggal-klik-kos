enum UserRole { admin, kosOwner, customer }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.kosOwner => 'Mitra Pemilik Kos',
        UserRole.customer => 'Pengguna',
      };

  String get route => switch (this) {
        UserRole.admin => '/admin',
        UserRole.kosOwner => '/owner',
        UserRole.customer => '/customer',
      };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.ownerVerified = false,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool ownerVerified;
}
