// // lib/services/accounts_file_service.dart

// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import '../config/app_users.dart';

// class AccountsFileService {
//   static const String fileName = 'accounts.txt';

//   // Singleton (optional, just for convenience)
//   static final AccountsFileService instance = AccountsFileService._internal();
//   AccountsFileService._internal();

//   Future<File> _getFile() async {
//     final dir = await getApplicationDocumentsDirectory();
//     return File('${dir.path}/$fileName');
//   }

//   // Default content if file doesn't exist yet
//   static const String _defaultContent = '''
// admin@example.com,password123,admin
// worker@example.com,123456,user
// ''';

//   Future<List<AppUser>> loadUsers() async {
//     final file = await _getFile();

//     if (!await file.exists()) {
//       // create file with default users
//       await file.writeAsString(_defaultContent.trim());
//     }

//     final text = await file.readAsString();
//     final lines = text.split('\n');

//     final List<AppUser> users = [];

//     for (final rawLine in lines) {
//       final line = rawLine.trim();
//       if (line.isEmpty) continue;

//       final parts = line.split(',');
//       if (parts.length < 3) continue; // skip bad lines

//       final email = parts[0].trim();
//       final password = parts[1].trim();
//       final roleStr = parts[2].trim().toLowerCase();

//       final role = roleStr == 'admin' ? UserRole.admin : UserRole.user;

//       users.add(AppUser(email: email, password: password, role: role));
//     }

//     return users;
//   }

//   Future<void> saveRaw(String content) async {
//     final file = await _getFile();
//     await file.writeAsString(content);
//   }

//   Future<String> loadRaw() async {
//     final file = await _getFile();
//     if (!await file.exists()) {
//       await file.writeAsString(_defaultContent.trim());
//     }
//     return file.readAsString();
//   }

//   /// Simple login helper: returns user if match, else null
//   Future<AppUser?> login(String email, String password) async {
//     final users = await loadUsers();
//     for (final u in users) {
//       if (u.email.toLowerCase() == email.toLowerCase() &&
//           u.password == password) {
//         return u;
//       }
//     }
//     return null;
//   }
// }
