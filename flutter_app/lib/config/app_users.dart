// lib/config/app_users.dart

enum UserRole { admin, user }

class AppUser {
  final String email;
  final String password;
  final UserRole role;
  final int id; // Add an ID field to uniquely identify users

  AppUser({required this.email, required this.password, required this.role, required this.id});

  @override
  String toString() => '$email,$password,$role.name,$id';
}
