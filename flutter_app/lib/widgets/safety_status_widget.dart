import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/status_colors.dart';
import '../Design/style_constant.dart';

enum SafetyStatus { dangerous, safe, na }

class SafetyStatusWidget extends StatelessWidget {
  final Map<String, dynamic>? aiData;
  final bool? isSpreaderUnlocked;

  const SafetyStatusWidget({
    super.key,
    required this.aiData,
    required this.isSpreaderUnlocked,
  });

  SafetyStatus get _status {
    if (aiData == null) return SafetyStatus.na;

    final String rawStatus = aiData!['overallStatus']?.toString() ?? 'N/A';
    switch (rawStatus.trim().toUpperCase()) {
      case 'DANGEROUS':
        return SafetyStatus.dangerous;
      case 'SAFE':
        return SafetyStatus.safe;
      default:
        return SafetyStatus.na;
    }
  }

  String _getStatusText(SafetyStatus status) {
    switch (status) {
      case SafetyStatus.dangerous:
        return "DANGEROUS";
      case SafetyStatus.safe:
        return "SAFE";
      case SafetyStatus.na:
        return "N/A";
    }
  }

  bool _shouldShowButton(SafetyStatus status) {
    if (status == SafetyStatus.na || aiData == null) return false;
    return aiData!.values.any((value) => value is Map<String, dynamic>);
  }

  String _formatCategoryKey(String key) {
    if (key == 'ppe') return 'PPE';
    final RegExp numUpperRegExp = RegExp(r'(?<=[a-z])(?=[A-Z])');
    final words = key.split(numUpperRegExp);
    return words
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  void _showReasonsDialog(BuildContext context) {
    final statusType = _status;
    final String overallStatusText = _getStatusText(statusType);

    final Color themeColor = SafetyStatusHelper.getColor(overallStatusText);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> dialogItems = [];

        if (isSpreaderUnlocked == true) {
          dialogItems.add(
            Container(
              margin: const EdgeInsets.only(bottom: AppPadding.medium),
              padding: const EdgeInsets.all(AppPadding.medium),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.priority_high_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: AppPadding.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ladder spreader is unlocked",
                          style: AppTypography.body.copyWith(
                            color: Colors.red[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Please lock the ladder's spreader",
                          style: AppTypography.faintbody.copyWith(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (aiData != null) {
          aiData!.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              final String categoryName = _formatCategoryKey(key);
              final String complianceStatus =
                  value['compliance']?.toString() ?? 'UNKNOWN';
              final Color subStatusColor = SafetyStatusHelper.getColor(
                complianceStatus,
              );

              dialogItems.add(
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppPadding.medium,
                    bottom: AppPadding.tight,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryName.toUpperCase(),
                        style: AppTypography.body.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.tight,
                          vertical: AppPadding.tight,
                        ),
                        decoration: BoxDecoration(
                          color: subStatusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSmall,
                          ),
                        ),
                        child: Text(
                          complianceStatus.toUpperCase(),
                          style: AppTypography.body.copyWith(
                            color: subStatusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (value['description'] != null &&
                  value['description'].toString().trim().isNotEmpty) {
                dialogItems.add(
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 6,
                      bottom: 6,
                      right: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "• ",
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                        Expanded(
                          child: Text(
                            "Description: ${value['description']}",
                            style: const TextStyle(
                              color: Color.fromARGB(255, 40, 40, 40),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (value['reasoning'] != null &&
                  value['reasoning'].toString().trim().isNotEmpty) {
                dialogItems.add(
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 6,
                      bottom: 6,
                      right: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "• ",
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                        Expanded(
                          child: Text(
                            "Reasoning: ${value['reasoning']}",
                            style: const TextStyle(
                              color: Color.fromARGB(255, 40, 40, 40),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (value['advice'] != null &&
                  value['advice'].toString().trim().isNotEmpty) {
                dialogItems.add(
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8, top: 4),
                    padding: const EdgeInsets.all(AppPadding.medium),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(
                          color: AppColors.primaryBlue,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CORRECTIVE ADVICE:",
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: AppPadding.tight),
                        Text(
                          value['advice'].toString().trim(),
                          style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          });
        }

        return AlertDialog(
          backgroundColor: AppColors.backgroundWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            side: BorderSide(
              color: themeColor.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    statusType == SafetyStatus.dangerous
                        ? Icons.report_problem_rounded
                        : Icons.assignment_turned_in_rounded,
                    color: themeColor,
                    size: AppDimensions.radiusLarge,
                  ),
                  const SizedBox(width: AppPadding.tight),
                  const Text(
                    "AI Safety Audit",
                    style: AppTypography.Bluesubheading,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.tight,
                  vertical: AppPadding.tight,
                ),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                  border: Border.all(color: themeColor, width: 1),
                ),
                child: Text(
                  overallStatusText,
                  style: AppTypography.body.copyWith(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: dialogItems,
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                textStyle: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CLOSE"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusType = _status;
    final String statusText = _getStatusText(statusType);
    final statusColor = SafetyStatusHelper.getColor(statusText);

    final String buttonLabel = statusType == SafetyStatus.dangerous
        ? "Why?"
        : "View Log";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppPadding.tight),
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          width: 1.5,
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusType == SafetyStatus.safe
                ? Icons.check_circle
                : (statusType == SafetyStatus.na
                      ? Icons.help_outline
                      : Icons.warning),
            color: statusColor,
            size: 28,
          ),
          const SizedBox(width: AppPadding.tight),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Safety Status Assessment",
                  style: AppTypography.faintbody.copyWith(fontSize: 13),
                ),
                Text(
                  _getStatusText(statusType),
                  style: AppTypography.Bluesubheading.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (_shouldShowButton(statusType))
            ElevatedButton.icon(
              onPressed: () => _showReasonsDialog(context),
              icon: Icon(
                statusType == SafetyStatus.dangerous
                    ? Icons.info_outline
                    : Icons.analytics_outlined,
                size: 16,
              ),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: AppColors.backgroundWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.medium,
                  vertical: AppPadding.tight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
