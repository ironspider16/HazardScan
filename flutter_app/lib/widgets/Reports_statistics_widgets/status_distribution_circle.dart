import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

class StatusDistributionCircle extends StatelessWidget {
  final List<Map<String, dynamic>> reports;

  const StatusDistributionCircle({super.key, required this.reports});

  List<PieChartSectionData> _generateChartData() {
    final Map<String, Color> statusColors = {
      'SAFE': Colors.green,
      'DANGEROUS': Colors.red,
      'N/A': Colors.grey,
    };

    Map<String, int> statusCounts = {};
    for (var report in reports) {
      if (report["safety_variables"] != null) {
        final vars = report['safety_variables'];
        final status = vars != null ? (vars['Overall Status'] ?? 'N/A') : 'N/A';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
    }

    return statusCounts.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: statusColors[entry.key] ?? Colors.grey,
        radius: 90,
        title: '${entry.key}\n(${entry.value})',
        titlePositionPercentageOffset: 0.3,
        titleStyle: const TextStyle(
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
          "Overall Safety Status",
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
