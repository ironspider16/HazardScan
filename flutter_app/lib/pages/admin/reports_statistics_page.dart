import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsStatisticsPage extends StatefulWidget {
  const ReportsStatisticsPage({super.key});

  @override
  State<ReportsStatisticsPage> createState() => _ReportsStatisticsPageState();
}

class _ReportsStatisticsPageState extends State<ReportsStatisticsPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> reports = []; // Renamed from tasks
  bool isLoading = true;
  DateTimeRange? selectedRange;
  String? selectedCategory;
  String? selectedTitle;

  final List<String> categories = [
    'Work At Height',
    'Confined Space Work',
    'Chemical Hazard',
  ];
  final List<String> titles = [
    'Ladder',
    'Personnel Lifter',
    'Scaffold',
    'Liquid Nitrogen (LN2) Transportation',
    'Liquid Nitrogen (LN2) Refilling',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    setState(() => isLoading = true);

    try {
      String selectQuery = '*, swp_templates!inner(id, category, title)';
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

      // 3. Filter by SWP Template Category
      if (selectedCategory != null) {
        query = query.eq('swp_templates.category', selectedCategory!);
      }

      // 4. Filter by SWP Template Title
      if (selectedTitle != null) {
        query = query.eq('swp_templates.title', selectedTitle!);
      }

      final response = await query.order('submitted_at', ascending: false);
      setState(() {
        reports = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });

      print(reports);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _showFilterDialog() async {
    // Temporary variables to hold choices inside the dialog setup box
    DateTimeRange? tempRange = selectedRange;
    String? tempCategory = selectedCategory;
    String? tempTitle = selectedTitle;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Filter Reports',
                style: AppTypography.Bluesubheading,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- DATE RANGE SECTION ---
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

                    // --- CATEGORY DROPDOWN ---
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

                    // --- TITLE DROPDOWN ---
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
                  ],
                ),
              ),
              actions: [
                // Clear All Active Filter Values Button
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      tempRange = null;
                      tempCategory = null;
                      tempTitle = null;
                    });
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save Dialog state back to Page state context
                    setState(() {
                      selectedRange = tempRange;
                      selectedCategory = tempCategory;
                      selectedTitle = tempTitle;
                    });
                    Navigator.pop(context);
                    loadReports(); // Fetch updated items
                  },
                  child: const Text('Apply Filters'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFiltering =
        selectedRange != null ||
        selectedCategory != null ||
        selectedTitle != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text("Dashboard", style: AppTypography.Bluesubheading),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_alt,
              color: isFiltering ? AppColors.primaryBlue : Colors.black,
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
                });
                loadReports();
              },
            ),
        ],
      ),

      // ================= BODY =================
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.page),
        child: Column(
          children: [
            const SizedBox(height: AppPadding.medium),
            // ================= TOP STATS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DashboardCircle(
                  icon: Icons.assignment_outlined,
                  value: reports.length.toString(),
                  label: "Total Reports",
                ),
                WorkActivityCircle(reports: reports),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================

// DASHBOARD CIRCLE

// =====================================================

class DashboardCircle extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const DashboardCircle({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: const BoxDecoration(
            color: AppColors.primaryTint,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

// =====================================================

// WORK ACTIVITY CIRCLE

// =====================================================

// =====================================================
// DYNAMIC WORK ACTIVITY CIRCLE
// =====================================================
class WorkActivityCircle extends StatelessWidget {
  final List<Map<String, dynamic>> reports;

  const WorkActivityCircle({super.key, required this.reports});

  // Helper function to turn "Work At Height" into "WAH"
  String _getAcronym(String text) {
    if (text.isEmpty || text == 'Unknown') return 'N/A';
    return text
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0])
        .join()
        .toUpperCase();
  }

  List<PieChartSectionData> _generateChartData() {
    // 1. Handle empty state gracefully
    if (reports.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey[300],
          radius: 90,
          title: 'No Data',
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        )
      ];
    }

    // 2. Count frequencies of each category
    Map<String, int> categoryCounts = {};
    for (var report in reports) {
      final category = report['swp_templates']?['category'] ?? 'Unknown';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    // 3. Define a nice color palette to cycle through
    final List<Color> palette = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      const Color.fromARGB(255, 175, 79, 76),
      Colors.purple,
      Colors.teal,
    ];

    // 4. Map the counts to pie chart sections
    int colorIndex = 0;
    return categoryCounts.entries.map((entry) {
      final color = palette[colorIndex % palette.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value.toDouble(), // Ratios handled automatically by FL Chart
        color: color,
        radius: 90,
        title: _getAcronym(entry.key), // E.g., 'CH' for Chemical Hazard
        titleStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: const BoxDecoration(
            color: AppColors.primaryTint,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(12),
          child: PieChart(
            PieChartData(
              sectionsSpace: 1,
              centerSpaceRadius: 0,
              sections: _generateChartData(), // Feed dynamic data here
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text("Work Activity", style: TextStyle(fontSize: 16)),
      ],
    );
  }
}

// =====================================================

// TASK CARD

// =====================================================

