import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/admin/manage_accounts_page.dart';
import 'package:flutter_application_1/pages/work_activity_page.dart';
import 'package:flutter_application_1/pages/admin/assign_task_page.dart';
import 'package:flutter_application_1/pages/admin/all_tasks_page.dart';
import 'package:flutter_application_1/pages/technician_task_page.dart';
import '../config/app_users.dart';
import '../pages/login_screen.dart';
import 'admin/add_accounts_page.dart';
import '../pages/reports_list_page.dart';
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
    final roleText = isAdmin ? "Admin" : "Technician";

    return Scaffold(
    backgroundColor: Colors.white,

    floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () async {
          final imagePath = await Navigator.push<String?>(
            context,
            MaterialPageRoute(builder: (_) => const CameraScreen()),
          );

          if (imagePath == null) return;

          // Ensure the widget is still in the tree before navigating
          if (context.mounted) {
            final confirmed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => ImageConfirmScreen(imagePath: imagePath),
              ),
            );

            if (confirmed == true) {
              debugPrint("Hazard scan confirmed and path saved: $imagePath");
            }
          }
        },
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔷 ICON
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.local_hospital, // or Icons.medical_services
                        color: Colors.white,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "HazardScan",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Hi, $roleText",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(height: 45),
                    if (isAdmin) ...[
                      _MenuButton(
                        label: "Assign Tasks",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AssignTaskPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      _MenuButton(
                        label: "All Tasks",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AllTasksPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      _MenuButton(
                        label: "Manage Worker Accounts",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageAccountsPage(),
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      _MenuButton(
                        label: "My Tasks",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TechnicianTaskPage(user:user)
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _MenuButton(label: "Profile", onTap: () {}),
                    ],
                  ],
                ),
              ),
            ),

            Positioned(
              right: 28,
              bottom: 45,
              child: GestureDetector(
                onTap: () => _logout(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 253, 27, 27),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Color.fromARGB(221, 255, 255, 255),
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuButton({required this.label, required this.onTap});

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: 500, // 🔥 wider
        height: 50, // 🔥 bigger
        alignment: Alignment.center,

        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFF2563EB) // 🔵 pressed
              : Colors.white, // ⚪ normal

          borderRadius: BorderRadius.circular(8),

          border: Border.all(
            color: const Color.fromARGB(255, 147, 147, 147), // outline
            width: 1,
          ),
        ),

        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            color: _pressed ? Colors.white : const Color(0xFF333333),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
