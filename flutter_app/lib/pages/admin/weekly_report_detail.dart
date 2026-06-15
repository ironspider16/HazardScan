import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class WeeklyReportDetailScreen extends StatelessWidget {
  final String content;
  final String startDate;
  final String endDate;

  const WeeklyReportDetailScreen({
    super.key,
    required this.content,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text(
          "Report: $startDate to $endDate",
          style: AppTypography.Bluesubheading,
        ),
      ),
      body:
        (Markdown(data: content,
        padding: EdgeInsets.all(AppPadding.page),))
    );
  }
}