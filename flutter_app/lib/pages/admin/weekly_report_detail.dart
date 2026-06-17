import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';

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
    final markdownStyle = MarkdownStyleSheet(
      h1: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors
            .primaryBlue, // Matches app header typography color anchors
        height: 1.4,
      ),
      h2: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryBlueLight,
        height: 1.5,
      ),
      h3: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
      p: const TextStyle(
        fontSize: 14,
        height: 1.6, // Adds breathing room between sentences
        color: AppColors.textMain,
      ),
      listBullet: const TextStyle(
        fontSize: 14,
        color: AppColors
            .primaryBlue, // Colors bullet anchors to stand out uniformly
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 1.0, color: Colors.grey.shade300),
        ),
      ),
      blockSpacing: AppPadding
          .medium, // Control padding intervals between structural text nodes
      listIndent: AppPadding.extraLarge,
    );
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(
        title: "Weekly Overview"
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppPadding.page,
              vertical: AppPadding.tight,
            ),
            padding: const EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.4),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.blue.shade800,
                  size: 20,
                ),
                const SizedBox(width: AppPadding.tight),
                Text(
                  "Reporting Period:",
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  "$startDate to $endDate",
                  style: AppTypography.body.copyWith(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Markdown(
              data: content,
              styleSheet: markdownStyle,
              padding: const EdgeInsets.all(AppPadding.page)
            )
          )
        ],
      ),
    );
  }
}
