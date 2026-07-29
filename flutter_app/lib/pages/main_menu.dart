import 'package:flutter/material.dart';
import 'package:kkhazardscan/main.dart';
import 'package:kkhazardscan/pages/admin/manage_submission_details_page.dart';
import 'package:kkhazardscan/pages/technician/technician_select_SWP.dart';
import 'package:kkhazardscan/supabase_client.dart';
import '../config/app_users.dart';
import '../Design/style_constant.dart';
import '../widgets/Menu_button.dart';
import 'admin/reports_statistics_page.dart';
import 'admin/reports_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkhazardscan/widgets/Reports_statistics_widgets/ai_telemetry_widget.dart';
import 'package:kkhazardscan/pages/admin/change_technician_password_page.dart';

class MainMenu extends StatelessWidget {
  final AppUser user;

  const MainMenu({super.key, required this.user});

  bool get isAdmin => user.role == UserRole.admin;

  Future<void> _logout(BuildContext context) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      // Handle logout error if necessary
      debugPrint("Logout error: $e");
    }
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const InitialAuthGateway()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {

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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppPadding.medium),

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
                        child: Image.asset(
                          'assets/images/Icon_kkh_512.png',
                          width: 100,
                          height: 100,
                        ),
                      ),

                      const SizedBox(height: AppPadding.medium),

                      const Text(
                        "HazardScan",
                        style: AppTypography.Blueheading,
                      ),

                      const SizedBox(height: AppPadding.tight),

                      const SizedBox(height: AppPadding.medium),

                      if (isAdmin) ...[
                        // const AiTelemetryWidget(),
                        MenuButton(
                          label: "Reports Statistics",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportsStatisticsPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppPadding.medium),

                        MenuButton(
                          label: "Reports List",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportsListPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppPadding.medium),

                        MenuButton(
                          label: "Manage Submission details",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ManageSubmissionDetailsPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppPadding.medium),

                        MenuButton(
                          label: "AI Analysis Metrics",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AiTelemetryPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppPadding.medium),

                        MenuButton(
                          label: "Change Password",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ChangeTechnicianPasswordPage(),
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        MenuButton(
                          label: "Submit Safety Report",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TechnicianSelectSwp(
                                  templateId: 1,
                                  categoryName: "1",
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      // Spacing clearance at the bottom so elements don't hide under the logout button
                      const SizedBox(height: 100),
                    ],
                  ),
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
