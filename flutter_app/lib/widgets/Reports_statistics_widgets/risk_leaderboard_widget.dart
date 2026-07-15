import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

class RiskLeaderboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboardData;

  const RiskLeaderboardWidget({super.key, required this.leaderboardData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Risk Leaderboard', style: AppTypography.Bluesubheading),
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
        ...leaderboardData.map((item) {
          return _buildRiskLeaderboardItem(
            item["category"],
            item["score"],
            item["totalWah"],
          );
        }),
      ],
    );
  }

  Widget _buildRiskLeaderboardItem(
    String categoryName,
    int rawScore,
    int totalWahReports,
  ) {
    final int maxScore = totalWahReports * 1;
    final double riskRatio = maxScore > 0 ? rawScore / maxScore : 0.0;
    final int riskPercentage = (riskRatio * 100).round();

    Color statusColor = Colors.green;
    Color backgroundColor = Colors.green.shade50;

    if (riskPercentage > 33 && riskPercentage <= 66) {
      statusColor = Colors.orange;
      backgroundColor = Colors.orange.shade50;
    } else if (riskPercentage > 66) {
      statusColor = Colors.red;
      backgroundColor = Colors.red.shade100;
    }

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
                  '• Raw Score: The total risk points accumulated from all reports.\n• Max Score: Calculated as (Total WAH Reports × 1 points).\n• Risk Percentage: Shows how close a category is to the worst-case scenario (100% risk).',
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
                _buildScoreRow('Dangerous', '+1'),
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
              color: points == '+1' ? Colors.red : Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}
