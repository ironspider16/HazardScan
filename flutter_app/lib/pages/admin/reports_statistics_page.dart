import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kkhazardscan/widgets/Menu_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/gestures.dart';

enum ChartTimeframe { oneWeek, twoWeeks, oneMonth, oneYear }

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
  String? selectedComplianceLevel;

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

  final List<String> complianceLevels = [
    'SAFE',
    'COMPLIANT',
    'PARTIALLY COMPLIANT',
    'DANGEROUS',
  ];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    setState(() => isLoading = true);

    try {
      String complianceJoinModifier = selectedComplianceLevel != null
          ? '!inner'
          : '';

      String selectQuery =
          '*, swp_templates!inner(id, category, title), WAH_safetyVariables_FK$complianceJoinModifier(*)';

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

      if (selectedComplianceLevel != null) {
        query = query.eq('swp_templates.category', 'Work At Height');
        query = query.eq(
          'WAH_safetyVariables_FK.Overall Status',
          selectedComplianceLevel!,
        );
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
    DateTimeRange? tempRange = selectedRange;
    String? tempCategory = selectedCategory;
    String? tempTitle = selectedTitle;
    String? tempComplianceLevel = selectedComplianceLevel;
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
                      tempComplianceLevel = null;
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
                MenuButton(
                  label: 'Apply Filters',
                  isPrimary: true,
                  width:
                      120, // Set a fixed width that fits the dialog action area
                  height: 40,
                  onTap: () {
                    setState(() {
                      selectedRange = tempRange;
                      selectedCategory = tempCategory;
                      selectedTitle = tempTitle;
                      selectedComplianceLevel = tempComplianceLevel;
                    });
                    Navigator.pop(context);
                    loadReports();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildChartContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryTint, // Light blue background
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Center(child: child),
    );
  }

  Map<String, Map<String, int>> _calculateComplianceRatios() {
    final Map<String, Map<String, int>> breakdown = {
      'Ladder Height': {
        'SAFE': 0,
        'COMPLIANT': 0,
        'PARTIALLY COMPLIANT': 0,
        'DANGEROUS': 0,
      },
      'PPE': {
        'SAFE': 0,
        'COMPLIANT': 0,
        'PARTIALLY COMPLIANT': 0,
        'DANGEROUS': 0,
      },
      'Buddy System': {
        'SAFE': 0,
        'COMPLIANT': 0,
        'PARTIALLY COMPLIANT': 0,
        'DANGEROUS': 0,
      },
      'Area Hazards': {
        'SAFE': 0,
        'COMPLIANT': 0,
        'PARTIALLY COMPLIANT': 0,
        'DANGEROUS': 0,
      },
    };

    String _getComplianceString(dynamic data) {
      if (data == null) return 'SAFE';
      final Map<String, dynamic> parsed = (data is String)
          ? Map<String, dynamic>.from(jsonDecode(data))
          : Map<String, dynamic>.from(data);
      return (parsed['compliance'] as String? ?? 'SAFE').toUpperCase();
    }

    for (var report in reports) {
      final vars = report['WAH_safetyVariables_FK'];
      if (vars != null) {
        final lh = _getComplianceString(vars['ladderheight']);
        if (breakdown['Ladder Height']!.containsKey(lh)) {
          breakdown['Ladder Height']![lh] =
              breakdown['Ladder Height']![lh]! + 1;
        }

        final ppe = _getComplianceString(vars['ppe']);
        if (breakdown['PPE']!.containsKey(ppe)) {
          breakdown['PPE']![ppe] = breakdown['PPE']![ppe]! + 1;
        }

        final bs = _getComplianceString(vars['buddySystem']);
        if (breakdown['Buddy System']!.containsKey(bs)) {
          breakdown['Buddy System']![bs] = breakdown['Buddy System']![bs]! + 1;
        }

        final ah = _getComplianceString(vars['areaHazards']);
        if (breakdown['Area Hazards']!.containsKey(ah)) {
          breakdown['Area Hazards']![ah] = breakdown['Area Hazards']![ah]! + 1;
        }
      }
    }

    return breakdown;
  }

  List<Map<String, dynamic>> _calculateRiskLeaderboard() {
    Map<String, int> scores = {
      'Ladder Height': 0,
      'PPE': 0,
      'Buddy System': 0,
      'Area Hazards': 0,
    };

    int totalWahReports = reports
        .where((r) => r["WAH_safetyVariables_FK"] != null)
        .length;

    // Helper to map compliance status to score
    int _getScore(String? compliance) {
      switch (compliance?.toUpperCase()) {
        case 'SAFE':
          return 0;
        case 'COMPLIANT':
          return 1;
        case 'PARTIALLY COMPLIANT':
          return 2;
        case 'DANGEROUS':
          return 4;
        default:
          return 0;
      }
    }

    // Helper to parse the JSON string or Map structure
    // Adjust logic if data arrives as Map vs String
    int _extractScore(dynamic data) {
      if (data == null) return 0;

      // If it is a string (JSON), decode it first
      final Map<String, dynamic> parsed = (data is String)
          ? Map<String, dynamic>.from(jsonDecode(data))
          : Map<String, dynamic>.from(data);

      return _getScore(parsed['compliance'] as String?);
    }

    for (var report in reports) {
      final vars = report['WAH_safetyVariables_FK'];
      if (vars != null) {
        scores['Ladder Height'] =
            scores['Ladder Height']! + _extractScore(vars['ladderheight']);
        scores['PPE'] = scores['PPE']! + _extractScore(vars['ppe']);
        scores['Buddy System'] =
            scores['Buddy System']! + _extractScore(vars['buddySystem']);
        scores['Area Hazards'] =
            scores['Area Hazards']! + _extractScore(vars['areaHazards']);
      }
    }

    // Convert to list and sort by score descending
    List<Map<String, dynamic>> leaderboard = scores.entries
        .map(
          (e) => {
            'category': e.key,
            'score': e.value,
            "totalWah": totalWahReports,
          },
        )
        .toList();

    leaderboard.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );
    return leaderboard;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(); // gets current time

    final bool isFiltering =
        selectedRange != null ||
        selectedCategory != null ||
        selectedTitle != null ||
        selectedComplianceLevel != null;

    final List<Map<String, dynamic>> leaderboard = _calculateRiskLeaderboard();

    final ratioData = _calculateComplianceRatios();

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
                  selectedComplianceLevel = null;
                });
                loadReports();
              },
            ),
        ],
      ),

      // ================= BODY =================
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppPadding.medium * 3),
              // ================= TOP STATS =================
              ReportTimelineWidget(reports: reports),
              const SizedBox(height: AppPadding.medium),
              LayoutBuilder(
                builder: (context, constraints) {
                  // If the screen is wider than 600px, use a row; otherwise, a column
                  bool isWide = constraints.maxWidth > 600;

                  if (isWide) {
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
                    return Center(
                      child: Column(
                        children: [
                          _buildChartContainer(
                            WorkActivityCircle(reports: reports),
                          ),
                          const SizedBox(height: AppPadding.medium),
                          _buildChartContainer(
                            StatusDistributionCircle(reports: reports),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppPadding.medium),
              _buildChartContainer(
                UnlockedSpreaderDistributionCircle(reports: reports),
              ),
              const SizedBox(height: AppPadding.medium),
              Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Compliance Distribution', style: AppTypography.body),
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
                    const Divider(height: 24),
                  ],
                ),
              ),
              RiskLeaderboardWidget(leaderboardData: leaderboard),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================

// DASHBOARD CIRCLE

// =====================================================

Widget _buildHorizontalStackedBar(
  String categoryName,
  Map<String, int> counts,
) {
  final int safe = counts['SAFE'] ?? 0;
  final int compliant = counts['COMPLIANT'] ?? 0;
  final int partial = counts['PARTIALLY COMPLIANT'] ?? 0;
  final int dangerous = counts['DANGEROUS'] ?? 0;

  final int total = safe + compliant + partial + dangerous;

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
            height: 26,
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
                        Expanded(
                          flex: safe,
                          child: Container(
                            color: Colors.green.shade600,
                            alignment: Alignment.center,
                            child: Text(
                              '$safe',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (compliant > 0)
                        Expanded(
                          flex: compliant,
                          child: Container(
                            color: Colors.green.shade300,
                            alignment: Alignment.center,
                            child: Text(
                              '$compliant',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (partial > 0)
                        Expanded(
                          flex: partial,
                          child: Container(
                            color: Colors.orange,
                            alignment: Alignment.center,
                            child: Text(
                              '$partial',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (dangerous > 0)
                        Expanded(
                          flex: dangerous,
                          child: Container(
                            color: Colors.red,
                            alignment: Alignment.center,
                            child: Text(
                              '$dangerous',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    ),
  );
}

class ReportTimelineWidget extends StatefulWidget {
  final List<Map<String, dynamic>> reports;

  const ReportTimelineWidget({super.key, required this.reports});

  @override
  State<ReportTimelineWidget> createState() => _ReportTimelineWidgetState();
}

class _ReportTimelineWidgetState extends State<ReportTimelineWidget> {
  ChartTimeframe _selectedTimeframe = ChartTimeframe.twoWeeks;

  int _getDaysCount() {
    switch (_selectedTimeframe) {
      case ChartTimeframe.oneWeek:
        return 7;
      case ChartTimeframe.twoWeeks:
        return 14;
      case ChartTimeframe.oneMonth:
        return 30;
      case ChartTimeframe.oneYear:
        return 365;
    }
  }

  List<DateTime> _generateDates(int days) {
    final now = DateTime.now();
    return List.generate(
      days,
      (i) => now.subtract(Duration(days: (days - 1) - i)),
    );
  }

  List<FlSpot> _getTimelineSpots(List<DateTime> datesList) {
    Map<String, int> dailyCounts = {
      for (var date in datesList) "${date.year}-${date.month}-${date.day}": 0,
    };

    for (var report in widget.reports) {
      if (report['submitted_at'] == null) continue;
      final date = DateTime.parse(report['submitted_at']);
      final key = "${date.year}-${date.month}-${date.day}";
      if (dailyCounts.containsKey(key)) {
        dailyCounts[key] = (dailyCounts[key] ?? 0) + 1;
      }
    }

    return dailyCounts.values.toList().asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.toDouble());
    }).toList();
  }

  Widget _buildTimeframeSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ChartTimeframe.values.map((timeframe) {
        bool isSelected = _selectedTimeframe == timeframe;
        String label = '';
        switch (timeframe) {
          case ChartTimeframe.oneWeek:
            label = "1W";
            break;
          case ChartTimeframe.twoWeeks:
            label = "2W";
            break;
          case ChartTimeframe.oneMonth:
            label = "1M";
            break;
          case ChartTimeframe.oneYear:
            label = "1Y";
            break;
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTimeframe = timeframe;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.black26,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Wraps the horizontal scroll view to permit mouse dragging on desktop
  Widget _buildScrollableArea({required Widget child}) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth;
        if (availableWidth == double.infinity) {
          availableWidth = MediaQuery.of(context).size.width;
        }

        bool isWide = availableWidth > 350;

        final int days = _getDaysCount();
        final List<DateTime> datesList = _generateDates(days);
        final List<FlSpot> spotsList = _getTimelineSpots(datesList);

        // Calculate maximum Y value and add 30% headroom to prevent tooltip clipping
        double calculatedMaxY = 0;
        for (var spot in spotsList) {
          if (spot.y > calculatedMaxY) calculatedMaxY = spot.y;
        }
        // Force a minimum scale of 5, otherwise add a buffer above the highest peak
        double chartMaxY = calculatedMaxY < 5
            ? 5
            : calculatedMaxY + (calculatedMaxY * 0.3);

        double baseChartWidth = isWide
            ? (availableWidth - 260)
            : (availableWidth - 40);
        double dynamicChartWidth = baseChartWidth;

        if (_selectedTimeframe == ChartTimeframe.twoWeeks) {
          dynamicChartWidth = max(baseChartWidth, 14 * 35.0);
        } else if (_selectedTimeframe == ChartTimeframe.oneMonth) {
          dynamicChartWidth = max(baseChartWidth, 30 * 30.0);
        } else if (_selectedTimeframe == ChartTimeframe.oneYear) {
          dynamicChartWidth = max(baseChartWidth, 365 * 14.0);
        }

        return Container(
          width: availableWidth,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: isWide
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                children: [
                  if (isWide)
                    const Text(
                      "Reports Timeline",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  _buildTimeframeSelector(),
                ],
              ),
              const SizedBox(height: 20),
              _buildLeftSection(),
              const SizedBox(height: 20),
              SizedBox(
                height: 220,
                child: _buildScrollableArea(
                  child: SizedBox(
                    width: dynamicChartWidth,
                    child: _buildChart(spotsList, datesList, chartMaxY),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeftSection() => SizedBox(
    width: 150,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.assignment_outlined, size: 50),
        const SizedBox(height: AppPadding.tight),
        Text(
          widget.reports.length.toString(),
          style: AppTypography.Blueheading,
        ),
        const Text("Total Reports"),
      ],
    ),
  );

  Widget _buildChart(
    List<FlSpot> spotsList,
    List<DateTime> datesList,
    double maxY,
  ) => LineChart(
    LineChartData(
      minY: 0,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) {
            return AppColors.primaryTint;
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spotsList,
          isCurved: false,
          color: Colors.black,
          barWidth: 3,
          preventCurveOverShooting: true,
        ),
      ],
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              int index = value.toInt();

              if (index < 0 || index >= datesList.length) {
                return const SizedBox.shrink();
              }

              if (_selectedTimeframe == ChartTimeframe.twoWeeks) {
                if (index % 2 != 0 && index != datesList.length - 1) {
                  return const SizedBox.shrink();
                }
              } else if (_selectedTimeframe == ChartTimeframe.oneMonth) {
                if (index % 5 != 0 && index != datesList.length - 1) {
                  return const SizedBox.shrink();
                }
              } else if (_selectedTimeframe == ChartTimeframe.oneYear) {
                if (index % 30 != 0 && index != datesList.length - 1) {
                  return const SizedBox.shrink();
                }
              }

              DateTime date = datesList[index];
              String formattedDate;

              if (_selectedTimeframe == ChartTimeframe.oneYear) {
                List<String> months = [
                  "Jan",
                  "Feb",
                  "Mar",
                  "Apr",
                  "May",
                  "Jun",
                  "Jul",
                  "Aug",
                  "Sep",
                  "Oct",
                  "Nov",
                  "Dec",
                ];
                formattedDate = months[date.month - 1];
              } else {
                formattedDate = "${date.day}/${date.month}";
              }

              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8,
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class RiskLeaderboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboardData;

  const RiskLeaderboardWidget({super.key, required this.leaderboardData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center, // Set to baseline
            children: [
              const Text(
                'Risk Leaderboard',
                style: AppTypography.Bluesubheading,
              ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                iconSize: 20,
                color: AppColors.primaryBlue,
                tooltip: 'Explain',
                onPressed: () => _showRiskExplanation(context),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.medium),
          ...leaderboardData.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            return _buildRiskLeaderboardItem(
              item["category"],
              item["score"],
              item["totalWah"],
            );
            //Padding(
            //   padding: const EdgeInsets.only(bottom: 12),
            //   child: Row(
            //     children: [
            //       Text(
            //         "${index + 1}",
            //         style: const TextStyle(
            //           fontWeight: FontWeight.bold,
            //           fontSize: 16,
            //         ),
            //       ),
            //       const SizedBox(width: 16),
            //       Expanded(
            //         child: Text(
            //           item['category'] as String,
            //           style: const TextStyle(fontSize: 16),
            //         ),
            //       ),
            //       Container(
            //         padding: const EdgeInsets.symmetric(
            //           horizontal: 12,
            //           vertical: 4,
            //         ),
            //         decoration: BoxDecoration(
            //           color: (item['score'] as int) > 10
            //               ? Colors.red.shade100
            //               : Colors.blue.shade50,
            //           borderRadius: BorderRadius.circular(8),
            //         ),
            //         child: Text(
            //           "${item['score']} pts",
            //           style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: (item['score'] as int) > 10
            //                 ? Colors.red
            //                 : Colors.blue,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // );
          }),
        ],
      ),
    );
  }

  Widget _buildRiskLeaderboardItem(
    String categoryName,
    int rawScore,
    int totalWahReports,
  ) {
    final int maxScore = totalWahReports * 4;

    final double riskRatio = maxScore > 0 ? rawScore / maxScore : 0.0;

    final int riskPercentage = (riskRatio * 100).round();

    Color statusColor;
    Color backgroundColor;

    if (riskPercentage <= 33) {
      statusColor = Colors.green;
      backgroundColor = Colors.green.shade50;
    } else if (riskPercentage <= 66) {
      statusColor = Colors.orange;
      backgroundColor = Colors.orange.shade50;
    } else {
      statusColor = Colors.red;
      backgroundColor = Colors.red.shade100;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.tight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text descriptive row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "$rawScore/$maxScore [$riskPercentage%]",
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.tight),

          // Visual progress row
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: riskRatio,
                    backgroundColor: AppColors.borderGrey.withValues(
                      alpha: 0.3,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRiskExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Risk Scoring Explanation',
            style: AppTypography.Bluesubheading,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This leaderboard tracks cumulative safety risks across all Work At Height audits. Higher scores indicate areas with more frequent or severe safety violations.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: AppPadding.medium),
                const Text(
                  'How Risk is measured',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: AppPadding.tight),
                const Text(
                  '• Raw Score: The total risk points accumulated from all reports.\n'
                  '• Max Score: Calculated as (Total WAH Reports × 4 points).\n'
                  '• Risk Percentage: Shows how close a category is to the worst-case scenario (100% risk).',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppPadding.medium),
                const Text(
                  'Point Weighting per Report:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: AppPadding.tight),
                _buildScoreRow('Dangerous', '+4'),
                _buildScoreRow('Partially Compliant', '+2'),
                _buildScoreRow('Compliant', '+1'),
                _buildScoreRow('Safe', '+0'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Helper to keep the score rows consistent
  Widget _buildScoreRow(String label, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            points,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: points == '+4' ? Colors.red : Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}

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

class StatusDistributionCircle extends StatelessWidget {
  final List<Map<String, dynamic>> reports;

  const StatusDistributionCircle({super.key, required this.reports});

  List<PieChartSectionData> _generateChartData() {
    // 1. Define order and colors for consistency
    final Map<String, Color> statusColors = {
      'SAFE': Colors.green,
      'COMPLIANT': Colors.blue,
      'PARTIALLY COMPLIANT': Colors.orange,
      'DANGEROUS': Colors.red,
      'N/A': Colors.grey,
    };

    // 2. Count statuses
    Map<String, int> statusCounts = {};
    for (var report in reports) {
      if (report["WAH_safetyVariables_FK"] != null) {
        final vars = report['WAH_safetyVariables_FK'];
        final status = (vars != null)
            ? (vars['Overall Status'] ?? 'N/A')
            : 'N/A';
        if (status != null) {
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
      }
    }

    // 3. Generate Sections
    return statusCounts.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: statusColors[entry.key] ?? Colors.grey,
        radius: 90,
        title: '${entry.key}\n(${entry.value})', // Shows Label + Number
        titlePositionPercentageOffset: 0.3,
        titleStyle: TextStyle(
          fontSize: 12,
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
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: _generateChartData(),
              sectionsSpace: 2,
              centerSpaceRadius: 0,
            ),
          ),
        ),
        const SizedBox(height: AppPadding.tight),
        const Text(
          "Overall Safety Status for Work at height",
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class UnlockedSpreaderDistributionCircle extends StatelessWidget {
  final List<Map<String, dynamic>> reports;

  const UnlockedSpreaderDistributionCircle({super.key, required this.reports});

  List<PieChartSectionData> _generateChartData() {
    if (reports.isEmpty) return [];

    final Map<bool, Color> statusColors = {
      true: Colors.red,
      false: Colors.green,
    };

    Map<bool, int> statusCounts = {true: 0, false: 0};

    for (var report in reports) {
      final vars = report['WAH_safetyVariables_FK'];
      if (vars != null) {
        final bool isUnlocked = vars['spreaderUnlocked'] ?? false;
        statusCounts[isUnlocked] = (statusCounts[isUnlocked] ?? 0) + 1;
      }
    }

    // 3. Generate Sections
    return statusCounts.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: statusColors[entry.key] ?? Colors.grey,
        radius: 90,
        title: entry.key == true
            ? 'Unlocked\n(${entry.value})'
            : 'locked\n(${entry.value})',
        titlePositionPercentageOffset: 0.3,
        titleStyle: TextStyle(
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
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: _generateChartData(),
              sectionsSpace: 2,
              centerSpaceRadius: 0,
            ),
          ),
        ),
        const SizedBox(height: AppPadding.tight),
        const Text(
          "Ladders with Unlocked spreader vs locked spreaders",
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class WorkActivityCircle extends StatefulWidget {
  final List<Map<String, dynamic>> reports;

  const WorkActivityCircle({super.key, required this.reports});

  @override
  State<WorkActivityCircle> createState() => _WorkActivityCircleState();
}

class _WorkActivityCircleState extends State<WorkActivityCircle> {
  int _touchedIndex = -1;

  String _getAcronym(String text) {
    if (text.isEmpty || text == 'Unknown') return 'N/A';
    return text
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0])
        .join()
        .toUpperCase();
  }

  // Helper to extract map of counts to keep order consistent
  Map<String, int> _getCategoryCounts() {
    Map<String, int> counts = {};
    for (var report in widget.reports) {
      final category = report['swp_templates']?['category'] ?? 'Unknown';
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return counts;
  }

  List<PieChartSectionData> _generateChartData(
    Map<String, int> categoryCounts,
  ) {
    final List<Color> palette = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      const Color.fromARGB(255, 175, 79, 76),
      Colors.purple,
      Colors.teal,
    ];

    int index = 0;
    return categoryCounts.entries.map((entry) {
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 18.0 : 15.0;
      final radius = isTouched ? 110.0 : 90.0;
      final color = palette[index % palette.length];

      final section = PieChartSectionData(
        value: entry.value.toDouble(),
        color: color,
        radius: radius,
        title:
            _getAcronym(entry.key) +
            "\n (" +
            entry.value.toInt().toString() +
            ")",
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      index++;
      return section;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categoryCounts = _getCategoryCounts();
    final keys = categoryCounts.keys.toList();

    // Determine the label to show below the chart
    String displayLabel = _touchedIndex >= 0 && _touchedIndex < keys.length
        ? keys[_touchedIndex]
        : "Tap a section for details";

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 0,
              sections: _generateChartData(categoryCounts),
            ),
          ),
        ),
        const SizedBox(height: AppPadding.tight),
        Text(displayLabel, style: AppTypography.body),
      ],
    );
  }
}
