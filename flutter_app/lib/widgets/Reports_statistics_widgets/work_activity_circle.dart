import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

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
      Colors.indigo,
      Colors.brown,
      Colors.black
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
        title: "${_getAcronym(entry.key)}\n (${entry.value.toInt()})",
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
