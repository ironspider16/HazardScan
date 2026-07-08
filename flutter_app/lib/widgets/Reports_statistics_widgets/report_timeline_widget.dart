import 'dart:math';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:kkhazardscan/pages/admin/reports_statistics_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth == double.infinity
            ? MediaQuery.of(context).size.width
            : constraints.maxWidth;

        bool isWide = availableWidth > 350;
        final int days = _getDaysCount();
        final List<DateTime> datesList = _generateDates(days);
        final List<FlSpot> spotsList = _getTimelineSpots(datesList);

        double calculatedMaxY = 0;
        for (var spot in spotsList) {
          if (spot.y > calculatedMaxY) calculatedMaxY = spot.y;
        }
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
              _buildSummaryRow(),
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

  Widget _buildTimeframeSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ChartTimeframe.values.map((timeframe) {
        bool isSelected = _selectedTimeframe == timeframe;
        String label = '';
        if (timeframe == ChartTimeframe.oneWeek) label = "1W";
        if (timeframe == ChartTimeframe.twoWeeks) label = "2W";
        if (timeframe == ChartTimeframe.oneMonth) label = "1M";
        if (timeframe == ChartTimeframe.oneYear) label = "1Y";

        return GestureDetector(
          onTap: () => setState(() => _selectedTimeframe = timeframe),
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

  Widget _buildSummaryRow() {
    return SizedBox(
      width: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
  }

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

  Widget _buildChart(
    List<FlSpot> spotsList,
    List<DateTime> datesList,
    double maxY,
  ) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => AppColors.primaryTint,
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
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                if (index < 0 || index >= datesList.length)
                  return const SizedBox.shrink();

                if (_selectedTimeframe == ChartTimeframe.twoWeeks &&
                    index % 2 != 0 &&
                    index != datesList.length - 1)
                  return const SizedBox.shrink();
                if (_selectedTimeframe == ChartTimeframe.oneMonth &&
                    index % 5 != 0 &&
                    index != datesList.length - 1)
                  return const SizedBox.shrink();
                if (_selectedTimeframe == ChartTimeframe.oneYear &&
                    index % 30 != 0 &&
                    index != datesList.length - 1)
                  return const SizedBox.shrink();

                DateTime date = datesList[index];
                String formattedDate =
                    _selectedTimeframe == ChartTimeframe.oneYear
                    ? [
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
                      ][date.month - 1]
                    : "${date.day}/${date.month}";

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
}
