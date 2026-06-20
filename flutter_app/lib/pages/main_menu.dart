import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kkhazardscan/pages/admin/manage_accounts_page.dart';
import 'package:kkhazardscan/pages/admin/manage_submission_details_page.dart';
import 'package:kkhazardscan/pages/technician/technician_select_SWP.dart';
import '../config/app_users.dart';
import '../pages/login_screen.dart';
import '../config/language_manager.dart';
import '../Design/style_constant.dart';
import '../widgets/Menu_button.dart';
import 'admin/reports_statistics_page.dart';
import 'admin/reports_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainMenu extends StatelessWidget {
  final AppUser user;

  const MainMenu({super.key, required this.user});

  bool get isAdmin => user.role == UserRole.admin;

  Future <void> _logout(BuildContext context) async {
    try{
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_registered_technician_device');
    } catch (e) {
      // Handle error
    }

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
                      child: SvgPicture.asset(
                        'assets/images/KKHlogo.svg',
                        width: 100,
                        height: 100,
                        semanticsLabel: 'Company Logo',
                      ),
                    ),

                    const SizedBox(height: AppPadding.medium),
                    
                    const Text("HazardScan", style: AppTypography.Blueheading),

                    const SizedBox(height: AppPadding.tight),

                    Text("Hi, $roleText", style: AppTypography.Bluesubheading),

                    const SizedBox(height: AppPadding.medium),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Language",
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: AppPadding.tight),
                        ValueListenableBuilder<Locale>(
                          valueListenable: AppLanguageManager.localeNotifier,
                          builder: (context, currentLocale, child) {
                            return DropdownButtonFormField<String>(
                              value: currentLocale.languageCode,
                              dropdownColor: Colors.white,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.textSecondary,
                              ),
                              style: AppTypography.body.copyWith(
                                color: AppColors.textMain,
                              ),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.language, size: 20),
                                fillColor: AppColors.backgroundWhite,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'en',
                                  child: Text("English"),
                                ),
                                DropdownMenuItem(
                                  value: 'zh',
                                  child: Text("中文"),
                                ),
                              ],
                              onChanged: (String? newLanguageCode) {
                                if (newLanguageCode != null) {
                                  AppLanguageManager.changeLanguage(
                                    newLanguageCode,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppPadding.medium),
                    if (isAdmin) ...[
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
                      const SizedBox(height: AppPadding.medium),
                      MenuButton(label: "Manage Submission details",
                      onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageSubmissionDetailsPage(),
                            ),
                          );
                        },)
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
