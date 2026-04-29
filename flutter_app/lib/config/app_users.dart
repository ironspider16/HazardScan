// lib/config/app_users.dart

enum UserRole { admin, user }

class AppUser {
  final String email;
  final String password;
  final UserRole role;

  AppUser({
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  String toString() => '$email,${password},${role.name}';
}
