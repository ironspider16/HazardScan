import 'package:flutter/material.dart';
import '../config/app_users.dart';
import '../pages/login_screen.dart';
import 'admin/edit_accounts_page.dart';
import '../pages/camera_screen.dart';
import '../pages/image_confirm_screen.dart';



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
      backgroundColor: Colors.black,

      // ---------------------------------------------------
      // TOP BAR WITH LOGOUT
      // ---------------------------------------------------
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          "Main Menu (${isAdmin ? 'Admin' : 'User'})",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
            tooltip: "Log Out",
          ),
        ],
      ),

      // Floating Camera Button
      floatingActionButton: FloatingActionButton(
  backgroundColor: const Color(0xFF2563EB),
  onPressed: () async {
    // 1. Open camera
    final imagePath = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );

    if (imagePath == null) {
      // User backed out of the camera
      return;
    }

    // 2. Show confirm / reject screen
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageConfirmScreen(imagePath: imagePath),
      ),
    );

    // 3. Handle result (optional)
    if (confirmed == true) {
      // Image was confirmed & "sent" to backend in ImageConfirmScreen
      // You could also refresh a list, navigate, etc.
      debugPrint("Image confirmed & sent: $imagePath");
    } else {
      debugPrint("User rejected image");
    }
  },
  child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          width: double.infinity,

          child: Column(
            children: [
              const SizedBox(height: 16),

              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ---- SHARED BUTTON ----
                        _MenuButton(
                          icon: Icons.description_outlined,
                          label: isAdmin ? "All Reports" : "My Reports",
                          color: const Color(0xFF2563EB),
                          onTap: () {},
                        ),
                        const SizedBox(height: 20),

                        // ---- ROLE-BASED BUTTONS ----
                        if (isAdmin) ...[
                          _MenuButton(
                            icon: Icons.group_outlined,
                            label: "User Management",
                            color: const Color(0xFF1F2937),
                            onTap: () {},
                          ),
                          const SizedBox(height: 20),
                          _MenuButton(
                            icon: Icons.settings_outlined,
                            label: "System Settings",
                            color: const Color(0xFF1F2937),
                            onTap: () {},
                          ),
                          const SizedBox(height: 20),
                          _MenuButton(
                            icon: Icons.edit_note_outlined,
                            label: "Edit Accounts",
                            color: const Color(0xFF1F2937),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EditAccountsPage()),
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                        ] else ...[
                          _MenuButton(
                            icon: Icons.assignment_turned_in_outlined,
                            label: "My Tasks",
                            color: const Color(0xFF1F2937),
                            onTap: () {},
                          ),
                          const SizedBox(height: 20),
                          _MenuButton(
                            icon: Icons.person_outline,
                            label: "Profile / Help",
                            color: const Color(0xFF1F2937),
                            onTap: () {},
                          ),
                        ],

                        const SizedBox(height: 40),

                        // ---------------------------------------------------
                        // OPTIONAL: LOGOUT BUTTON AT BOTTOM
                        // ---------------------------------------------------
                        TextButton(
                          onPressed: () => _logout(context),
                          child: const Text(
                            "Log Out",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
