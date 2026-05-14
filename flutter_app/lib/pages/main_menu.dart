import 'package:flutter/material.dart';
import 'package:kkhazardscan/pages/admin/manage_accounts_page.dart';
import 'package:kkhazardscan/pages/camera_page.dart';
import 'package:kkhazardscan/pages/admin/assign_task_page.dart';
import 'package:kkhazardscan/pages/admin/all_tasks_page.dart';
import 'package:kkhazardscan/pages/technician_task_page.dart';
import '../config/app_users.dart';
import '../pages/login_screen.dart';
import '../pages/image_confirm_screen.dart';
import 'dart:typed_data';
import '../Design/style_constant.dart';
import '../widgets/Menu_button.dart';

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
          final result = await Navigator.push<Map<String, dynamic>?>(
            context,
            MaterialPageRoute(builder: (_) => const CameraPage()),
          );

          if (result == null) return;

          final imagePath = result['imagePath'] as String;
          final imageBytes = result['imageBytes'] as Uint8List;

          // Ensure the widget is still in the tree before navigating
          if (context.mounted) {
            final confirmed = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageConfirmScreen(
                  imagePath: imagePath,
                  imageBytes: imageBytes,
                ),
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.page,
                ),
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔷 ICON
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLarge,
                        ),
                      ),
                      child: const Icon(
                        Icons.local_hospital, // or Icons.medical_services
                        color: Colors.white,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: AppPadding.medium),
                    const Text("HazardScan", style: AppTypography.Blueheading),

                    const SizedBox(height: AppPadding.tight),

                    Text("Hi, $roleText", style: AppTypography.Bluesubheading),

                    const SizedBox(height: AppPadding.extraLarge),
                    if (isAdmin) ...[
                      MenuButton(
                        label: "Assign Tasks",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AssignTaskPage()),
                          );
                        },
                      ),
                      const SizedBox(height: AppPadding.medium),

                      MenuButton(
                        label: "All Tasks",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AllTasksPage()),
                          );
                        },
                      ),
                      const SizedBox(height: AppPadding.medium),

                      MenuButton(
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
                      MenuButton(
                        label: "My Tasks",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TechnicianTaskPage(user: user),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppPadding.medium),
                      MenuButton(label: "Profile", onTap: () {}),
                    ],
                  ],
                ),
              ),
            ),

            Positioned(
              right: AppPadding.medium,
              bottom: AppPadding.Largest,
              child: GestureDetector(
                onTap: () => _logout(context),
                child: Container(
                  width: AppPadding.Largest,
                  height: AppPadding.Largest,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 253, 27, 27),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppColors.backgroundWhite,
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
