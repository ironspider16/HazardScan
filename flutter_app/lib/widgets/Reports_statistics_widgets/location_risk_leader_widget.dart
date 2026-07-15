import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

class LocationRiskLeaderboardWidget extends StatelessWidget {
  final Map<String, double> locationDangerAverages;

  const LocationRiskLeaderboardWidget({
    super.key,
    required this.locationDangerAverages,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Location Risk Leaderboard',
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
        ...locationDangerAverages.entries.map((entry) {
          return _buildRiskLeaderboardItem(entry.key, entry.value);
        }),
      ],
    );
  }

  Widget _buildRiskLeaderboardItem(String locationName, double rawScore) {
    Color statusColor = Colors.green;
    Color backgroundColor = Colors.green.shade50;

    if (rawScore > 0.2 && rawScore <= 0.6) {
      statusColor = Colors.orange;
      backgroundColor = Colors.orange.shade50;
    } else if (rawScore > 0.6) {
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
              Expanded(
                child: Text(
                  locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${rawScore.toStringAsFixed(2)}/1",
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
                    value: rawScore / 1,
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
                  'This leaderboard tracks average safety risks across all Work At Height locations. Higher scores indicate areas with more frequent or severe safety violations.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: AppPadding.medium),
                const Text(
                  'How Risk is measured',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: AppPadding.tight),
                const Text(
                  '• Average score: The sum of risk score divided by total reports for each location.\n• Max Score: 1 point because that is the highest risk level.',
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
