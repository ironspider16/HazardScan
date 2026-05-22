import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../design/style_constant.dart';
import '../../widgets/Menu_button.dart';

class ReportsListPage extends StatefulWidget {
  const ReportsListPage({super.key});

  @override
  State<ReportsListPage> createState() => _ReportsListPageState();
}

class _ReportsListPageState extends State<ReportsListPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> reports = []; // Renamed from tasks
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReports(); // Changed method name
  }

  Future<void> loadReports() async {
    setState(() => isLoading = true);

    try {
      // Assuming your table is named 'safety_reports'
      final response = await supabase
          .from('safety_reports')
          .select('''*,
          swp_templates (
           id,
           category,
           title
          )
          ''')
          .order('submitted_at', ascending: false);

      setState(() {
        reports = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });

      debugPrint(reports.toString());
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reports: $e')));
      }
    }
  }

  Widget _reportCard(Map<String, dynamic> report) {
    final String techName = report['technician_name'] ?? 'Unknown Technician';
    final String details = report['Details'] ?? 'No details provided';
    final String date = report['submitted_at'] ?? '';
    final String department = report['department'] ?? 'N/A';
    final String SafetyProcedure = report['swp_templates']['category'] ?? 'N/A';
    final String SafetyProcedure_category =
        report['swp_templates']['title'] ?? 'N/A';
    final String designation = report["designation"] ?? 'N/A';
    final String permit_Number =
        report['wah_permit_numbers'] ?? ""; 
    final String location = report['location'] ?? 'No location';

    return Container(
      margin: const EdgeInsets.only(top: AppPadding.medium),
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderGrey.withAlpha(75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$techName: $SafetyProcedure | $SafetyProcedure_category",
            style: AppTypography.Blacksubheading,
          ),
          const SizedBox(height: AppPadding.medium),
          _buildInfoRow(Icons.location_history_outlined, location),
          const SizedBox(height: AppPadding.tight),
          _buildInfoRow(Icons.person, "Designation: $designation"),
          const SizedBox(height: AppPadding.tight),
          _buildInfoRow(Icons.business_outlined, "Department: $department"),
          if ((permit_Number.trim().isNotEmpty)) ...[
            const SizedBox(height: AppPadding.tight),
            _buildInfoRow(Icons.perm_identity, "Ptw Number: $permit_Number"),
          ],
          const SizedBox(height: AppPadding.tight),
          _buildInfoRow(Icons.calendar_today, date),
          const SizedBox(height: AppPadding.tight),
          Container(
            color: Colors.blue[50],
            child: ExpansionTile(
              title: const Text('Details', style: AppTypography.body),
              children: <Widget>[
                Align(
                  alignment: Alignment
                      .centerLeft, 
                  child: Padding(
                    padding: const EdgeInsets.all(
                      16.0,
                    ), 
                    child: Text(details, style: AppTypography.body),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryBlue),
        const SizedBox(width: AppPadding.tight),
        Expanded(child: Text(text, style: AppTypography.body)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.page),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 31,
                      color: Colors.black,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'All Reports',
                        style: AppTypography.Bluesubheading,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppPadding.Largest),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : reports.isEmpty
                    ? const Center(child: Text('No reports found'))
                    : ListView.builder(
                        itemCount: reports.length,
                        itemBuilder: (context, index) =>
                            _reportCard(reports[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
