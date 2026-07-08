import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

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

    return statusCounts.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: statusColors[entry.key] ?? Colors.grey,
        radius: 90,
        title: entry.key == true
            ? 'Unlocked\n(${entry.value})'
            : 'locked\n(${entry.value})',
        titlePositionPercentageOffset: 0.3,
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
