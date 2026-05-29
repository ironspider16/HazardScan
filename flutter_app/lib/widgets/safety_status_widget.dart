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

  // Helper to parse the main overall status string into an enum
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

  // Define colors for each status type (Used across widget frames and pills)
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

  // Helper to parse dynamic category compliance raw strings on the fly
  Color _getColorFromRawString(String statusStr) {
    switch (statusStr.trim().toUpperCase()) {
      case 'DANGEROUS':
        return Colors.red.shade700;
      case 'PARTIALLY COMPLIANT':
        return Colors.orange.shade700;
      case 'COMPLIANT':
        return AppColors.primaryBlue;
      case 'SAFE':
        return Colors.green.shade700;
      default:
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

  // Updated: Button shows for any valid parsed data summary logs
  bool _shouldShowButton(SafetyStatus status) {
    return status != SafetyStatus.na && reasons.isNotEmpty;
  }

  void _showReasonsDialog(BuildContext context) {
    final statusType = _status;
    final themeColor = _getStatusColor(statusType);
    final String overallStatusText = _getStatusText(statusType);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundWhite, // Deep dark premium card background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            side: BorderSide(color: themeColor.withOpacity(0.2), width: 1.5),
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
                    style: AppTypography.Bluesubheading
                  ),
                ],
              ),
              // Right-aligned overall safety badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.tight, vertical: AppPadding.tight),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
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
                children: reasons.map((reason) {
                  final bool isRecommendation = reason.startsWith("Recommendation:");
                  final bool isCategoryHeader = !reason.startsWith("[") && 
                                                !isRecommendation && 
                                                reason.contains(":");

                  // 1. Structural Category Title Banner Header Layout
                  if (isCategoryHeader) {
                    final parts = reason.split(":");
                    final String categoryName = parts[0].trim();
                    final String complianceStatus = parts[1].trim();
                    final Color subStatusColor = _getColorFromRawString(complianceStatus);

                    return Padding(
                      padding: const EdgeInsets.only(top: AppPadding.medium, bottom: AppPadding.tight),
                      child: Column(
                        children: [
                          Row(
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
                                padding: const EdgeInsets.symmetric(horizontal: AppPadding.tight, vertical: AppPadding.tight),
                                decoration: BoxDecoration(
                                  color: subStatusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
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
                          const SizedBox(height: AppPadding.tight),

                        ],
                      ),
                    );
                  }
                  
                  // 2. Blueprint Actionable Recommendation Callout Box Layout
                  else if (isRecommendation) {
                    final adviceText = reason.replaceFirst("Recommendation:", "").trim();
                    
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8, top: 2),
                      padding: const EdgeInsets.all(AppPadding.medium),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          left: BorderSide(color: Colors.blueAccent, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "CORRECTIVE ADVICE:",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                        ),
                          ),
                          const SizedBox(height: AppPadding.tight),
                          Text(
                            adviceText,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  } 
                  
                  // 3. Generic/Factual Observations Layout Box Frame
                  else {
                    String category = "OBSERVATION";
                    String bodyText = reason;
                    
                    if (reason.startsWith("[")) {
                      final closingBracketIdx = reason.indexOf("]");
                      if (closingBracketIdx != -1) {
                        category = reason.substring(1, closingBracketIdx);
                        bodyText = reason.substring(closingBracketIdx + 1).trim();
                      }
                    }

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(AppPadding.medium),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(color: AppColors.borderGrey, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.toUpperCase(),
                            style: AppTypography.faintbody.copyWith(
                              color: const Color.fromARGB(221, 0, 0, 0),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppPadding.tight),
                          Text(
                            bodyText,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }).toList(),
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
    final statusColor = _getStatusColor(statusType);

    // Contextual adjustment for card button labels
    final String buttonLabel = (statusType == SafetyStatus.dangerous || 
                                statusType == SafetyStatus.partiallyCompliant)
        ? "Why?"
        : "View Log";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppPadding.tight),
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(width: 1.5, color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            statusType == SafetyStatus.safe || statusType == SafetyStatus.compliant
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
                statusType == SafetyStatus.dangerous || statusType == SafetyStatus.partiallyCompliant
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