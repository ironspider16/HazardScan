import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkhazardscan/pages/admin/past_weekly_reports_page.dart';
import 'package:kkhazardscan/pages/admin/past_monthly_reports_page.dart';
import 'package:kkhazardscan/widgets/Reports_statistics_widgets/location_risk_leader_widget.dart';
import 'package:kkhazardscan/widgets/Reports_statistics_widgets/report_timeline_widget.dart';
import 'package:kkhazardscan/widgets/Reports_statistics_widgets/risk_leaderboard_widget.dart';
import 'package:kkhazardscan/widgets/Reports_statistics_widgets/status_distribution_circle.dart';
import 'package:kkhazardscan/widgets/Reports_statistics_widgets/unlocked_spreader_distribution_circle.dart';
import 'package:kkhazardscan/widgets/Reports_statistics_widgets/work_activity_circle.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:kkhazardscan/pages/admin/weekly_report_detail.dart';
import 'package:kkhazardscan/pages/admin/monthly_report_detail.dart';
import 'package:kkhazardscan/widgets/Menu_button.dart';

// ==========================================
// ENUMS
// ==========================================

enum ChartTimeframe { oneWeek, twoWeeks, oneMonth, oneYear }

// ==========================================
// MAIN WIDGET ENTRY POINT
// ==========================================

class ReportsStatisticsPage extends StatefulWidget {
  const ReportsStatisticsPage({super.key});

  @override
  State<ReportsStatisticsPage> createState() => _ReportsStatisticsPageState();
}

class _ReportsStatisticsPageState extends State<ReportsStatisticsPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  // State Variables
  List<Map<String, dynamic>> reports = [];
  Map<String, dynamic>? weeklyReport;
  bool isLoading = true;
  bool isWeeklyReportLoading = true;
  Map<String, dynamic>? monthlyReport;
  bool isMonthlyReportLoading = true;

  // Active Filter States
  DateTimeRange? selectedRange;
  String? selectedCategory;
  String? selectedTitle;
  String? selectedComplianceLevel;
  String? selectedLocation;
  String? selectedDepartment;
  bool sortAscending = false;

  // Filter Configuration Constants
  List<String> categories = [];
  List<String> titles = [];
  List<String> departments = [];
  List<String> locations = [];
  List<String> complianceLevels = ['SAFE', 'DANGEROUS'];

  // ==========================================
  // LIFECYCLE METHODS
  // ==========================================

  @override
  void initState() {
    super.initState();
    loadWeeklyReport();
    loadMonthlyReport();
    loadReports();
  }

  // ==========================================
  // DATA FETCHING & SERVICES
  // ==========================================

  Future<void> loadWeeklyReport() async {
    setState(() => isWeeklyReportLoading = true);

    try {
      final today = DateTime.now();

      final response = await supabase
          .from('weekly_reports')
          .select()
          .lte('end_date', today.toIso8601String().split('T')[0])
          .order('end_date', ascending: false)
          .limit(1);

      setState(() {
        weeklyReport = response.isNotEmpty ? response.first : null;
        isWeeklyReportLoading = false;
      });
      return;
    } catch (e) {
      setState(() {
        weeklyReport = null;
        isWeeklyReportLoading = false;
      });
    }
  }

  Future<void> loadMonthlyReport() async {
    if (!mounted) return;

    setState(() => isMonthlyReportLoading = true);

    try {
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      debugPrint('Loading monthly report for date: $today');

      final List<dynamic> response = await supabase
          .from('monthly_reports')
          .select()
          .lte('end_date', today)
          .order('end_date', ascending: false)
          .order('created_at', ascending: false)
          .limit(1);

      debugPrint('Monthly report response: $response');

      if (!mounted) return;

      setState(() {
        monthlyReport = response.isNotEmpty
            ? Map<String, dynamic>.from(response.first)
            : null;

        isMonthlyReportLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Monthly report loading error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        monthlyReport = null;
        isMonthlyReportLoading = false;
      });
    }
  }

  Future<void> loadFilterLists() async {
    try {
      final templatesData = await supabase
          .from("swp_templates")
          .select("category , title");
      Set<String> setCategories = {};
      Set<String> setTitles = {};
      Set<String> setLocations = {};
      Set<String> setDepartments = {};

      setCategories = templatesData
          .map((item) => item["category"].toString())
          .whereType<String>()
          .where((category) => category.isNotEmpty)
          .toSet();

      setTitles = templatesData
          .map((item) => item["title"].toString())
          .whereType<String>()
          .where((title) => title.isNotEmpty)
          .toSet();

      setLocations = reports
          .map((r) => r["location"]?.toString().trim())
          .whereType<String>()
          .where((location) => location.isNotEmpty)
          .toSet();

      setDepartments = reports
          .map((d) => d["department"]?.toString().trim())
          .whereType<String>()
          .where((department) => department.isNotEmpty)
          .toSet();

      setState(() {
        categories = setCategories.toList();
        titles = setTitles.toList();
        locations = setLocations.toList();
        departments = setDepartments.toList();
      });
    } catch (e) {
      debugPrint("Error loading filter lists: $e");
    }
  }

  Future<void> loadReports() async {
    setState(() => isLoading = true);

    try {
      final bool filterbyCompliance = selectedComplianceLevel != null;
      String selectQuery = filterbyCompliance
          ? '*, swp_templates!inner(id, category, title), safety_variables_FK!inner(*)'
          : '*, swp_templates!inner(id, category, title), safety_variables_FK(*)';

      PostgrestFilterBuilder query = supabase
          .from('safety_reports')
          .select(selectQuery);

      if (selectedRange != null) {
        query = query
            .gte('submitted_at', selectedRange!.start.toIso8601String())
            .lte(
              'submitted_at',
              selectedRange!.end.add(const Duration(days: 1)).toIso8601String(),
            );
      }

      // Filter by SWP Template Category
      if (selectedCategory != null) {
        query = query.eq('swp_templates.category', selectedCategory!);
      }

      // Filter by SWP Template Title
      if (selectedTitle != null) {
        query = query.eq('swp_templates.title', selectedTitle!);
      }

      if (selectedComplianceLevel != null) {
        query = query.eq(
          'safety_variables_FK.Overall Status',
          selectedComplianceLevel!,
        );
      }

      if (selectedLocation != null) {
        query = query.eq('location', selectedLocation!);
      }

      if (selectedDepartment != null) {
        query = query.eq('department', selectedDepartment!);
      }

      final response = await query.order(
        'submitted_at',
        ascending: sortAscending,
      );
      setState(() {
        reports = List<Map<String, dynamic>>.from(response);
        debugPrint(reports.toString());
        isLoading = false;
      });
      loadFilterLists();
    } catch (e) {
      setState(() => isLoading = false);
    }
  }
  // ==========================================
  // BUSINESS LOGIC & DATA TRANSFORMATIONS
  // ==========================================

  Map<String, Map<String, int>> _calculateComplianceRatios() {
    final Map<String, Map<String, int>> breakdown = {
      'Ladder Height': {'SAFE': 0, 'DANGEROUS': 0},
      'PPE': {'SAFE': 0, 'DANGEROUS': 0},
      'Buddy System': {'SAFE': 0, 'DANGEROUS': 0},
      'Area Hazards': {'SAFE': 0, 'DANGEROUS': 0},
      'Electrical And Machinery': {'SAFE': 0, 'DANGEROUS': 0},
    };

    for (var report in reports) {
      final vars = report['safety_variables_FK'];
      if (vars != null) {
        _incrementBreakdownCount(
          breakdown,
          'Ladder Height',
          vars['ladderheight'],
        );
        _incrementBreakdownCount(breakdown, 'PPE', vars['ppe']);
        _incrementBreakdownCount(
          breakdown,
          'Buddy System',
          vars['buddySystem'],
        );
        _incrementBreakdownCount(
          breakdown,
          'Area Hazards',
          vars['areaHazards'],
        );
        _incrementBreakdownCount(
          breakdown,
          'Electrical And Machinery',
          vars['electricalMachinery'],
        );
      }
    }
    return breakdown;
  }

  void _incrementBreakdownCount(
    Map<String, Map<String, int>> breakdown,
    String key,
    dynamic data,
  ) {
    if (data == null) return;
    final Map<String, dynamic> parsed = (data is String)
        ? Map<String, dynamic>.from(jsonDecode(data))
        : Map<String, dynamic>.from(data);
    final status = (parsed['compliance'] as String? ?? 'SAFE').toUpperCase();

    if (breakdown[key]!.containsKey(status)) {
      breakdown[key]![status] = breakdown[key]![status]! + 1;
    }
  }

  List<Map<String, dynamic>> _calculateRiskLeaderboard() {
    final Map<String, int> scores = {
      'Ladder Height': 0,
      'PPE': 0,
      'Buddy System': 0,
      'Area Hazards': 0,
      'Electrical And Machinery': 0,
    };

    final totalReports = reports
        .where((r) => r["safety_variables_FK"] != null)
        .length;

    for (var report in reports) {
      final vars = report['safety_variables_FK'];
      if (vars != null) {
        scores['Ladder Height'] =
            scores['Ladder Height']! + _extractScore(vars['ladderheight']);
        scores['PPE'] = scores['PPE']! + _extractScore(vars['ppe']);
        scores['Buddy System'] =
            scores['Buddy System']! + _extractScore(vars['buddySystem']);
        scores['Area Hazards'] =
            scores['Area Hazards']! + _extractScore(vars['areaHazards']);
        scores['Electrical And Machinery'] =
            scores['Electrical And Machinery']! +
            _extractScore(vars['electricalMachinery']);
      }
    }

    final List<Map<String, dynamic>> leaderboard = scores.entries
        .map(
          (e) => {'category': e.key, 'score': e.value, "total": totalReports},
        )
        .toList();

    leaderboard.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );
    return leaderboard;
  }

  int _extractScore(dynamic data) {
    if (data == null) return 0;
    final Map<String, dynamic> parsed = (data is String)
        ? Map<String, dynamic>.from(jsonDecode(data))
        : Map<String, dynamic>.from(data);

    switch (parsed['compliance'] as String?) {
      case 'SAFE':
        return 0;
      case 'DANGEROUS':
        return 1;
      default:
        return 0;
    }
  }

  int getScore(compliance) {
    final scores = {"SAFE": 0, "DANGEROUS": 1};
    return scores[(compliance.toString().toUpperCase())] ?? 0;
  }

  Map<String, double> calculateLocationDangerAverage(List<dynamic> data) {
    // Map to track lookups: Key = Location, Value = [TotalScore, Count]
    final Map<String, List<num>> tracker = {};

    for (var r in data) {
      final String location = r['location'] ?? 'Unknown';

      if (r['safety_variables_FK'] != null) {
        final String? status = r['safety_variables_FK']['Overall Status'];
        final int score = getScore(status); // Using your scoring logic helper

        if (!tracker.containsKey(location)) {
          tracker[location] = [score, 1];
        } else {
          tracker[location]![0] += score;
          tracker[location]![1] += 1;
        }
      }
    }

    // Map to hold finalized average calculations
    final Map<String, double> finalizedAverages = {};

    tracker.forEach((location, values) {
      final num totalScore = values[0];
      final num count = values[1];
      finalizedAverages[location] = totalScore / count;
    });

    var sortedfinalizedAverages = Map.fromEntries(
      finalizedAverages.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    return sortedfinalizedAverages;
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

  // ==========================================
  // DIALOGS & FILTERS
  // ==========================================

  void _showFilterDialog() async {
    DateTimeRange? tempRange = selectedRange;
    String? tempCategory = selectedCategory;
    String? tempTitle = selectedTitle;
    String? tempComplianceLevel = selectedComplianceLevel;
    String? tempLocation = selectedLocation;
    String? tempDepartment = selectedDepartment;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Reports', style: AppTypography.Bluesubheading),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryTint,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: AppTypography.Blacksubheading.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppPadding.tight),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: tempRange,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => tempRange = picked);
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        tempRange == null
                            ? 'Select Date Range'
                            : '${tempRange?.start.toString().split(' ')[0]} to ${tempRange?.end.toString().split(' ')[0]}',
                      ),
                    ),
                    const SizedBox(height: AppPadding.medium),

                    Text(
                      'Category',
                      style: AppTypography.Blacksubheading.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: tempCategory,
                      hint: const Text('All Categories'),
                      items: categories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() => tempCategory = newValue);
                      },
                    ),
                    const SizedBox(height: AppPadding.tight),

                    Text(
                      'Title',
                      style: AppTypography.Blacksubheading.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: tempTitle,
                      hint: const Text('All Titles'),
                      items: titles.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() => tempTitle = newValue);
                      },
                    ),
                    Text(
                      'Compliance Level',
                      style: AppTypography.Blacksubheading.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: tempComplianceLevel,
                      hint: const Text('All Levels'),
                      items: complianceLevels.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() => tempComplianceLevel = newValue);
                      },
                    ),
                    Text(
                      'Location',
                      style: AppTypography.Blacksubheading.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: tempLocation,
                      hint: const Text('All Locations'),
                      items: locations.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() => tempLocation = newValue);
                      },
                    ),
                    Text(
                      'Department',
                      style: AppTypography.Blacksubheading.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: tempDepartment,
                      hint: const Text('All Departments'),
                      items: departments.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() => tempDepartment = newValue);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: MenuButton(
                        label: "Clear All",
                        isMini: true,
                        isDelete: true,
                        onTap: () {
                          setDialogState(() {
                            tempRange = null;
                            tempCategory = null;
                            tempComplianceLevel = null;
                            tempTitle = null;
                            tempDepartment = null;
                            tempLocation = null;
                          });
                          setState(() {
                            selectedRange = null;
                            selectedCategory = null;
                            selectedComplianceLevel = null;
                            selectedTitle = null;
                            selectedDepartment = null;
                            selectedLocation = null;
                          });
                          loadReports();
                        },
                      ),
                    ),
                    const SizedBox(width: AppPadding.tight),
                    Expanded(
                      child: MenuButton(
                        label: 'Apply Filters',
                        isPrimary: true,
                        isMini: true,
                        onTap: () {
                          setState(() {
                            selectedRange = tempRange;
                            selectedCategory = tempCategory;
                            selectedTitle = tempTitle;
                            selectedComplianceLevel = tempComplianceLevel;
                            selectedLocation = tempLocation;
                            selectedDepartment = tempDepartment;
                          });
                          Navigator.pop(context);
                          loadReports();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // MAIN BUILD METHOD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final bool isFiltering =
        selectedRange != null ||
        selectedCategory != null ||
        selectedTitle != null ||
        selectedComplianceLevel != null ||
        selectedDepartment != null ||
        selectedLocation != null;

    final leaderboard = _calculateRiskLeaderboard();
    final ratioData = _calculateComplianceRatios();
    final locationDangerAverages = calculateLocationDangerAverage(reports);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(
        title: "Dashboard",
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_alt,
              color: isFiltering ? AppColors.primaryBlue : AppColors.textMain,
            ),
            onPressed: _showFilterDialog,
          ),
          if (isFiltering)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () {
                setState(() {
                  selectedRange = null;
                  selectedCategory = null;
                  selectedTitle = null;
                  selectedComplianceLevel = null;
                  selectedDepartment = null;
                  selectedLocation = null;
                });
                loadReports();
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.radiusMedium),
                child: CircularProgressIndicator(),
              ),
            )
          : reports.isEmpty
          ? _buildEmptyState(isFiltering)
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.page,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppPadding.medium * 3),
                    ReportTimelineWidget(reports: reports),
                    const SizedBox(height: AppPadding.medium),
                    _buildResponsiveChartsRow(),
                    const SizedBox(height: AppPadding.medium),
                    _buildChartContainer(
                      UnlockedSpreaderDistributionCircle(reports: reports),
                    ),
                    const SizedBox(height: AppPadding.medium),
                    _buildComplianceDistributionCard(ratioData),
                    const SizedBox(height: AppPadding.medium),
                    _buildChartContainer(
                      RiskLeaderboardWidget(leaderboardData: leaderboard),
                    ),
                    const SizedBox(height: AppPadding.medium),
                    _buildWeeklyReportSection(),
                    const SizedBox(height: AppPadding.medium),
                    _buildMonthlyReportSection(),
                    const SizedBox(height: AppPadding.medium),
                    _buildChartContainer(
                      LocationRiskLeaderboardWidget(
                        locationDangerAverages: locationDangerAverages,
                      ),
                    ),

                    const SizedBox(height: AppPadding.medium),
                  ],
                ),
              ),
            ),
    );
  }

  // ==========================================
  // INTERNALLY SCOPED UI SUB-BUILDERS
  // ==========================================

  Widget _buildChartContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildResponsiveChartsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildChartContainer(
                  WorkActivityCircle(reports: reports),
                ),
              ),
              const SizedBox(width: AppPadding.medium),
              Expanded(
                child: _buildChartContainer(
                  StatusDistributionCircle(reports: reports),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildChartContainer(WorkActivityCircle(reports: reports)),
              const SizedBox(height: AppPadding.medium),
              _buildChartContainer(StatusDistributionCircle(reports: reports)),
            ],
          );
        }
      },
    );
  }

  Widget _buildComplianceDistributionCard(
    Map<String, Map<String, int>> ratioData,
  ) {
    return _buildChartContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compliance Distribution',
            style: AppTypography.Bluesubheading,
          ),
          const SizedBox(height: AppPadding.medium),
          _buildHorizontalStackedBar(
            'Ladder Height',
            ratioData['Ladder Height']!,
          ),
          _buildHorizontalStackedBar('PPE', ratioData['PPE']!),
          _buildHorizontalStackedBar(
            'Buddy System',
            ratioData['Buddy System']!,
          ),
          _buildHorizontalStackedBar(
            'Area Hazards',
            ratioData['Area Hazards']!,
          ),
          _buildHorizontalStackedBar(
            'Electrical And Machinery',
            ratioData['Electrical And Machinery']!,
          ),
          const Divider(height: 24),
          _buildComplianceLegend(),
        ],
      ),
    );
  }

  Widget _buildHorizontalStackedBar(
    String categoryName,
    Map<String, int> counts,
  ) {
    final int safe = counts['SAFE'] ?? 0;
    final int dangerous = counts['DANGEROUS'] ?? 0;
    final int total = safe + dangerous;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.tight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '$total Audits',
                style: AppTypography.body.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.tight),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 50,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: total == 0
                  ? const Center(
                      child: Text(
                        'No record entries available',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    )
                  : Row(
                      children: [
                        if (safe > 0)
                          _buildBarSegment(safe, Colors.green.shade600),
                        if (dangerous > 0)
                          _buildBarSegment(dangerous, Colors.red),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarSegment(int flexValue, Color color) {
    return Expanded(
      flex: flexValue,
      child: Container(
        color: color,
        alignment: Alignment.center,
        child: Text(
          '$flexValue',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildComplianceLegend() {
    return Wrap(
      spacing: AppPadding.tight,
      runSpacing: AppPadding.tight,
      children: [
        _buildLegendItem("Safe", Colors.green.shade600),
        _buildLegendItem("Dangerous", Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.tight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: AppPadding.tight),
          Text(label, style: AppTypography.body),
        ],
      ),
    );
  }

  Widget _buildWeeklyReportSection() {
    if (isWeeklyReportLoading) {
      return _buildChartContainer(
        const Center(child: CircularProgressIndicator()),
      );
    }

    if (weeklyReport == null) {
      return _buildChartContainer(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Weekly Safety Report",
              style: AppTypography.Bluesubheading,
            ),
            const SizedBox(height: AppPadding.tight),
            Text(
              "No management report has been generated for today yet.",
              style: AppTypography.body.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final content = weeklyReport!['report_content'] as String? ?? '';
    final startDate = weeklyReport!['start_date'] as String? ?? '';
    final endDate = weeklyReport!['end_date'] as String? ?? '';
    final int id = weeklyReport!['id'];

    return _buildChartContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            direction: Axis.horizontal,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppPadding.medium,
            runSpacing: AppPadding.tight,
            children: [
              const Text(
                "Weekly Safety Report",
                style: AppTypography.Bluesubheading,
              ),
              Text(
                "$startDate to $endDate",
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.medium),
          Text(
            content.length > 90 ? '${content.substring(0, 90)}...' : content,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppPadding.medium),
          MenuButton(
            label: "View Full Report",
            isPrimary: true,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeeklyReportDetailScreen(
                    content: content,
                    date: formatDateRange(startDate, endDate),
                    id: id,
                  ),
                ),
              );

              loadWeeklyReport();
            },
          ),
          const Divider(height: 24.0, thickness: 1.0),
          MenuButton(
            label: "View All Weekly Reports",
            isPrimary: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AllWeeklyReportsPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReportSection() {
    if (isMonthlyReportLoading) {
      return _buildChartContainer(
        const Center(child: CircularProgressIndicator()),
      );
    }

    if (monthlyReport == null) {
      return _buildChartContainer(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Monthly Safety Report",
              style: AppTypography.Bluesubheading,
            ),
            const SizedBox(height: AppPadding.tight),
            Text(
              "No management report has been generated for today yet.",
              style: AppTypography.body.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final content = monthlyReport!['report_content'] as String? ?? '';
    final startDate = monthlyReport!['start_date'] as String? ?? '';
    final endDate = monthlyReport!['end_date'] as String? ?? '';
    final int id = monthlyReport!['id'];

    return _buildChartContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            direction: Axis.horizontal,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppPadding.medium,
            runSpacing: AppPadding.tight,
            children: [
              const Text(
                "Monthly Safety Report",
                style: AppTypography.Bluesubheading,
              ),
              Text(
                "$startDate to $endDate",
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.medium),
          Text(
            content.length > 90 ? '${content.substring(0, 90)}...' : content,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppPadding.medium),
          MenuButton(
            label: "View Full Report",
            isPrimary: true,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MonthlyReportDetailScreen(
                    content: content,
                    date: formatDateRange(startDate, endDate),
                    id: id,
                  ),
                ),
              );

              loadMonthlyReport();
            },
          ),
          const Divider(height: 24.0, thickness: 1.0),
          MenuButton(
            label: "View All Monthly Reports",
            isPrimary: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllMonthlyReportsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isFiltering) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.page,
          vertical: 60,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFiltering
                  ? 'No Matching Reports Found'
                  : 'No Reports Available',
              style: AppTypography.Bluesubheading,
            ),
            const SizedBox(height: AppPadding.tight),
            Text(
              isFiltering
                  ? 'None of the safety reports match your selected filters.'
                  : 'There are currently no safety reports submitted in the system.',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppPadding.medium * 2),
            if (isFiltering)
              SizedBox(
                width: 200,
                child: MenuButton(
                  label: 'Clear All Filters',
                  isDelete: true,
                  onTap: () {
                    setState(() {
                      selectedRange = null;
                      selectedCategory = null;
                      selectedTitle = null;
                      selectedComplianceLevel = null;
                      selectedLocation = null;
                      selectedDepartment = null;
                    });
                    loadReports();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
