// lib/config/app_users.dart

class AppUser {
  final String email;
  final String password;

  const AppUser({
    required this.email,
    required this.password,
  });
}

class AppUsersConfig {
  //  Add your allowed users here
  static const List<AppUser> users = [
    AppUser(email: 'admin@example.com', password: 'password123'),
    AppUser(email: 'user@example.com', password: '123456'),
  ];

  static bool validate(String email, String password) {
    for (final u in users) {
      if (u.email.toLowerCase() == email.toLowerCase() &&
          u.password == password) {
        return true;
      }
    }
    return false;
  }
}
