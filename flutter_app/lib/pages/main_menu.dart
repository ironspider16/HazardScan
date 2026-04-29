import 'package:flutter/material.dart';
import '../config/app_users.dart';
import '../pages/login_screen.dart';
import 'admin/edit_accounts_page.dart';
import '../pages/camera_screen.dart';
import '../pages/image_confirm_screen.dart';
import '../pages/reports_list_page.dart';
import '../pages/swp_category_page.dart';

class MainMenu extends StatelessWidget {
  final AppUser user;

  const MainMenu({super.key, required this.user});

  bool get isAdmin => user.role == UserRole.admin;

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

      // ------------------ APP BAR ------------------
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Text(
          "Main Menu (${isAdmin ? 'Admin' : 'User'})",
          style: const TextStyle(color: Color(0xFF2563EB)),
        ),
        centerTitle: true,
        actions: [],
      ),

      // ------------------ ACTION FABS (LOGOUT + CAMERA) ------------------
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.redAccent,
            onPressed: () => _logout(context),
            child: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Log Out',
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            backgroundColor: const Color(0xFF2563EB),
            onPressed: () async {
              final imagePath = await Navigator.push<String?>(
                context,
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              );

              if (imagePath == null) return;

              final confirmed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageConfirmScreen(imagePath: imagePath),
                ),
              );

              if (confirmed == true) {
                debugPrint("Image confirmed & sent: $imagePath");
              }
            },
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // ------------------ BODY ------------------
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // -------- REPORTS BUTTON --------
                  _MenuButton(
                    icon: Icons.description_outlined,
                    label: isAdmin ? "All Reports" : "My Reports",
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportsListPage(isAdmin: isAdmin),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // -------- ROLE-BASED BUTTONS --------
                  if (isAdmin) ...[
                    _MenuButton(
                      icon: Icons.edit_note_outlined,
                      label: "Edit Accounts",
                      color: const Color(0xFF1F2937),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditAccountsPage(),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    _MenuButton(
                      icon: Icons.assignment_turned_in_outlined,
                      label: "My Tasks",
                      color: const Color.fromARGB(255, 157, 157, 157),
                      onTap: () {
                        // TODO: Implement user tasks if needed
                      },
                    ),
                  ],

                  const SizedBox(height: 40),

                  // (Logout moved to FAB column)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------ MENU BUTTON WIDGET ------------------
class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
