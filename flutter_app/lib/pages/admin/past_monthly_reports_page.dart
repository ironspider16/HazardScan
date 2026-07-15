import 'package:flutter/material.dart';
import 'package:kkhazardscan/pages/admin/monthly_report_detail.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../design/style_constant.dart';
import 'package:intl/intl.dart';

class AllMonthlyReportsPage extends StatefulWidget {
  const AllMonthlyReportsPage({super.key});

  @override
  State<AllMonthlyReportsPage> createState() => PastMonthlyReportsPageState();
}

class PastMonthlyReportsPageState extends State<AllMonthlyReportsPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> monthlyReports = [];
  bool isLoading = true;
  DateTimeRange? selectedRange;

  @override
  void initState() {
    super.initState();
    loadMonthlyReports();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadMonthlyReports() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from("monthly_reports")
          .select()
          .order("start_date", ascending: false);

      setState(() {
        monthlyReports = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String formatDateRange(String startDate, String endDate) {
    try {
      DateTime start = DateTime.parse(startDate);
      DateTime end = DateTime.parse(endDate);

      DateFormat monthDayFormat = DateFormat('MMM d');
      DateFormat yearFormat = DateFormat('yyyy');

      String startFormatted = monthDayFormat.format(start);
      String endFormatted = monthDayFormat.format(end);
      String yearFormatted = yearFormat.format(end);

      return "$startFormatted - $endFormatted, $yearFormatted";
    } catch (e) {
      return "Unknown Date";
    }
  }

  Widget _monthlyReportCard(Map<String, dynamic> report, int index) {
    final String startDate = report["start_date"]?.toString() ?? "";
    final String endDate = report["end_date"]?.toString() ?? "";
    final content = report['report_content']?.toString() ?? "";
    final int id = report['id'] is int
        ? report['id']
        : int.tryParse(report['id']?.toString() ?? '0') ?? 0;

    final String formattedDate = formatDateRange(startDate, endDate);
    final int position = monthlyReports.length - index;

    return Container(
      margin: const EdgeInsets.only(top: AppPadding.medium),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      // Clip contents so the splash effect stays inside the border radius
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MonthlyReportDetailScreen(
                  id: id,
                  date: formattedDate,
                  content: content,
                ),
              ),
            );

            loadMonthlyReports();
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main card details content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Monthly Report $position",
                                    style:
                                        AppTypography.Blacksubheading.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppPadding.tight),
                                  Chip(
                                    label: Text(formattedDate),
                                    avatar: const Icon(Icons.calendar_month),
                                    side: const BorderSide(
                                      style: BorderStyle.none,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.black.withValues(alpha: 0.35),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(title: "Archived Monthly Reports"),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Column(
            children: [
              const SizedBox(height: AppPadding.tight),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : monthlyReports.isEmpty
                    ? const Center(
                        child: Text(
                          "No Monthly reports found.",
                          style: AppTypography.Blacksubheading,
                        ),
                      )
                    : ListView.builder(
                        itemCount: monthlyReports.length,
                        itemBuilder: (context, index) {
                          final report = monthlyReports[index];
                          return _monthlyReportCard(report, index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
