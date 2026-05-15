import 'package:flutter/material.dart';
import 'package:kkhazardscan/pages/admin/manage_accounts_page.dart';
import 'package:kkhazardscan/pages/technician_task_page.dart';
import '../config/app_users.dart';
import '../pages/login_screen.dart';
import '../Design/style_constant.dart';
import '../widgets/Menu_button.dart';
import 'admin/dashboard.dart';

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
                        label: "Dashboard",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DashboardPage()),
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
