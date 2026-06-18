import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:kkhazardscan/pages/admin/manage_departments_page.dart';
import 'package:kkhazardscan/pages/admin/manage_designations_page.dart';
import 'package:kkhazardscan/pages/admin/manage_locations_page.dart';
import 'package:kkhazardscan/widgets/Menu_button.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';

class ManageSubmissionDetailsPage extends StatefulWidget {
  const ManageSubmissionDetailsPage({super.key});

  @override
  State<ManageSubmissionDetailsPage> createState() =>
      _ManageSubmissionDetailsState();
}

class _ManageSubmissionDetailsState extends State<ManageSubmissionDetailsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(title: "Manage Submission Details"),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppPadding.extraLarge),
              MenuButton(
                label: "Manage Locations",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageLocationsPage(),
                    ),
                  );
                },
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: AppPadding.medium),
              MenuButton(
                label: "Manage Departments",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageDepartmentsPage(),
                    ),
                  );
                },
                icon: Icons.business_center_outlined,
              ),
              const SizedBox(height: AppPadding.medium),
              MenuButton(
                label: "Manage Designations",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageDesignationsPage(),
                    ),
                  );
                },
                icon: Icons.badge_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
