import 'package:flutter/material.dart';
import '../Design/style_constant.dart';

enum SafetyStatus { dangerous, partiallyCompliant, compliant, safe, na }

class SafetyStatusWidget extends StatelessWidget {
  final String rawStatus;
  final List<String> reasons;

  const SafetyStatusWidget({
    super.key,
    required this.rawStatus,
    required this.reasons,
  });

  // Helper to parse the raw string into an enum
  SafetyStatus get _status {
    switch (rawStatus.trim().toUpperCase()) {
      case 'DANGEROUS':
        return SafetyStatus.dangerous;
      case 'PARTIALLY COMPLIANT':
        return SafetyStatus.partiallyCompliant;
      case 'COMPLIANT':
        return SafetyStatus.compliant;
      case 'SAFE':
        return SafetyStatus.safe;
      default:
        return SafetyStatus.na;
    }
  }

  // Define colors for each status type
  Color _getStatusColor(SafetyStatus status) {
    switch (status) {
      case SafetyStatus.dangerous:
        return Colors.red.shade700;
      case SafetyStatus.partiallyCompliant:
        return Colors.orange.shade700;
      case SafetyStatus.compliant:
        return AppColors.primaryBlue;
      case SafetyStatus.safe:
        return Colors.green.shade700;
      case SafetyStatus.na:
        return Colors.grey.shade600;
    }
  }

  // Define display text for each status type
  String _getStatusText(SafetyStatus status) {
    switch (status) {
      case SafetyStatus.dangerous:
        return "DANGEROUS";
      case SafetyStatus.partiallyCompliant:
        return "PARTIALLY COMPLIANT";
      case SafetyStatus.compliant:
        return "COMPLIANT";
      case SafetyStatus.safe:
        return "SAFE";
      case SafetyStatus.na:
        return "N/A";
    }
  }

  // Logic to determine if a "Show Reasons" button is needed
  bool _shouldShowButton(SafetyStatus status) {
    return status == SafetyStatus.dangerous ||
        status == SafetyStatus.partiallyCompliant;
  }

  void _showReasonsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _status == SafetyStatus.dangerous
                    ? Icons.report_problem
                    : Icons.warning_amber_rounded,
                color: _getStatusColor(_status),
              ),
              const SizedBox(width: AppPadding.tight),
              const Text("AI Hazard Findings"),
            ],
          ),
          content: SingleChildScrollView(
            child: reasons.isEmpty
                ? const Text(
                    "No specific reasons provided by the analysis system.",
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: reasons
                        .map(
                          (reason) => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppPadding.tight / 2,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "• ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: AppTypography.body,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusType = _status;
    final statusColor = _getStatusColor(statusType);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppPadding.tight),
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: statusColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            statusType == SafetyStatus.safe ||
                    statusType == SafetyStatus.compliant
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
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text("Why?"),
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
