import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/status_Colors.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';

class ReportsDetailPage extends StatefulWidget {
  const ReportsDetailPage({super.key, required this.report});
  final Map<String, dynamic> report;
  @override
  State<ReportsDetailPage> createState() => _ReportsDetailPageState();
}

class _ReportsDetailPageState extends State<ReportsDetailPage> {
  late final Map<String, dynamic> safetyVar;
  late final String location;
  late final String designation;
  late final String department;
  late final String details;
  late final String ptwNumber;
  late final String techName;
  late final String date;
  late final String reportCode;
  late final String category;

  @override
  void initState() {
    super.initState();
    safetyVar = widget.report['safety_variables_FK'] ?? {};
    final String location =
        widget.report['location']?.toString() ?? 'No location';
    final String designation =
        widget.report['designation']?.toString() ?? 'N/A';
    final String department = widget.report['department']?.toString() ?? 'N/A';
    final String details =
        widget.report['Details']?.toString() ?? 'No details provided';
    final String ptwNumber =
        widget.report['wah_permit_numbers']?.toString() ?? 'N/A';
    final String techName =
        widget.report['technician_name']?.toString() ?? 'N/A';
    final String date = widget.report['submitted_at']?.toString() ?? 'N/A';
    final String reportCode = widget.report["report_code"]?.toString() ?? 'unknown ID';
    final String category = "${widget.report['swp_templates']?['category']} - ${widget.report['swp_templates']?['title']}";
    setState(() {
      this.location = location;
      this.designation = designation;
      this.department = department;
      this.details = details;
      this.ptwNumber = ptwNumber;
      this.techName = techName;
      this.date = date;
      this.reportCode = reportCode;
      this.category = category;
    });
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.0, color: AppColors.primaryBlue),
          const SizedBox(width: AppPadding.tight),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.body,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildReasonsList(Map<String, dynamic> safetyVar) {
    final List<String> reasons = [];

    void parseCategory(String label, dynamic categoryData) {
      if (categoryData == null) return;
      Map<String, dynamic> data = {};

      if (categoryData is Map) {
        data = Map<String, dynamic>.from(categoryData);
      } else if (categoryData is String) {
        try {
          data = Map<String, dynamic>.from(jsonDecode(categoryData));
        } catch (_) {}
      }

      if (data.isNotEmpty) {
        final compliance = data['compliance'] ?? 'N/A';
        final description = data['description'] ?? '';
        final reasoning = data['reasoning'] ?? '';
        final advice = data['advice'] ?? '';

        reasons.add("$label: $compliance");
        if (description.isNotEmpty) {
          reasons.add("• DESCRIPTION: $description");
        }
        if (reasoning.isNotEmpty) {
          reasons.add("• REASONING: $reasoning");
        }
        if (advice.isNotEmpty) {
          reasons.add("Recommendation: $advice");
        }
      }
    }

    parseCategory("LADDER HEIGHT", safetyVar['ladderheight']);
    parseCategory("PPE", safetyVar['ppe']);
    parseCategory("BUDDY SYSTEM", safetyVar['buddySystem']);
    parseCategory("HOUSEKEEPING AND AREA HAZARDS", safetyVar['areaHazards']);
    parseCategory("ELECTRICAL AND MACHINERY", safetyVar['electricalMachinery']);

    return reasons;
  }

  @override
  Widget build(BuildContext context) {
    // Modified: Extract status logic to variables for cleaner container building and N/A handling
    final String rawStatus = safetyVar['Overall Status'] ?? 'N/A';
    final String overallStatus = 'Overall Status: $rawStatus'.toUpperCase();
    final Color statusColor = SafetyStatusHelper.getColor(rawStatus);

    return Scaffold(
      appBar: const UniversalAppBar(title: 'Reports Detail Page'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: AppColors.primaryTint,
              surfaceTintColor: AppColors.primaryTint,
              margin: const EdgeInsets.all(AppPadding.medium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportCode,
                      style: AppTypography.Blackheading.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: AppPadding.tight / 2),
                    Text(
                      "Submitted by: $techName on $date",
                      style: AppTypography.faintbody.copyWith(
                        fontSize: 13,
                        color: AppColors.textMain.withValues(alpha: 50),
                      ),
                    ),
                    const Divider(height: 24.0, thickness: 1.0),

                    if (ptwNumber != 'N/A')
                      _buildInfoRow(
                        Icons.assignment_turned_in,
                        'PTW Number',
                        ptwNumber,
                      ),
                    _buildInfoRow(Icons.business, 'Department', department),
                    _buildInfoRow(Icons.badge, 'Designation', designation),
                    _buildInfoRow(Icons.location_on, 'Location', location),
                    _buildInfoRow(Icons.category, 'Category', category),
                    Text(
                      'Details',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppPadding.tight),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppPadding.tight),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Text(
                        details,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppPadding.medium,
                    AppPadding.tight,
                    AppPadding.medium,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modified: Significantly increased padding and font size for the status container
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.tight,
                          vertical: AppPadding.tight,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(26),
                        ),

                        child: Text(
                          overallStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0, // Increased from 10
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildReasonsList(safetyVar).map((reason) {
                          final String trimmed = reason.trim();
                          if (trimmed.isEmpty) return const SizedBox.shrink();

                          final String upperReason = trimmed.toUpperCase();

                          final bool isRecommendation =
                              trimmed.startsWith("Recommendation:") ||
                              upperReason.startsWith("• ADVICE:") ||
                              upperReason.contains("ADVICE:");

                          final bool isCategoryHeader =
                              !trimmed.startsWith("•") &&
                              !trimmed.startsWith("[") &&
                              !isRecommendation &&
                              trimmed.contains(":") &&
                              (upperReason.contains("COMPLIANT") ||
                                  upperReason.contains("DANGEROUS") ||
                                  upperReason.contains("SAFE") ||
                                  upperReason.contains("N/A"));

                          final bool isBulletDetail =
                              trimmed.startsWith("•") ||
                              upperReason.startsWith("DESCRIPTION:") ||
                              upperReason.startsWith("REASONING:");

                          if (isCategoryHeader) {
                            final parts = trimmed.split(":");
                            final String categoryName = parts[0].trim();
                            final String complianceStatus = parts.length > 1
                                ? parts[1].trim()
                                : "N/A";
                            final Color subStatusColor =
                                SafetyStatusHelper.getColor(complianceStatus);

                            return Padding(
                              padding: const EdgeInsets.only(
                                top: AppPadding.large,
                                bottom: AppPadding.medium,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    categoryName.toUpperCase(),
                                    // Modified: Increased header font size
                                    style: AppTypography.body.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: subStatusColor.withAlpha(30),
                                      borderRadius: BorderRadius.circular(0),
                                    ),
                                    child: Text(
                                      complianceStatus.toUpperCase(),
                                      // Modified: Increased sub-status font size
                                      style: AppTypography.body.copyWith(
                                        color: subStatusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (isRecommendation) {
                            String adviceText = trimmed;
                            if (adviceText.startsWith("Recommendation:")) {
                              adviceText = adviceText
                                  .replaceFirst("Recommendation:", "")
                                  .trim();
                            } else if (adviceText.startsWith("•")) {
                              String temp = adviceText.substring(1).trim();
                              if (temp.toUpperCase().startsWith("ADVICE:")) {
                                adviceText = temp.substring(7).trim();
                              } else {
                                adviceText = temp;
                              }
                            } else if (adviceText.toUpperCase().startsWith(
                              "ADVICE:",
                            )) {
                              adviceText = adviceText.substring(7).trim();
                            }

                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12, top: 6),
                              padding: const EdgeInsets.all(AppPadding.medium),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: const Border(
                                  left: BorderSide(
                                    color: Colors.blueAccent,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "CORRECTIVE ADVICE:",
                                    // Modified: Increased font size for advice label
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
                                    // Modified: Increased body text size
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (isBulletDetail) {
                            String bodyText = trimmed;
                            if (bodyText.startsWith("•")) {
                              bodyText = bodyText.substring(1).trim();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                bottom: 8,
                                right: 8,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "• ",
                                    style: TextStyle(
                                      color: Colors.black45,
                                      fontSize:
                                          12, // Modified: Increased bullet size
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      bodyText,
                                      // Modified: Increased body text size
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            String category = "OBSERVATION";
                            String bodyText = trimmed;

                            if (trimmed.startsWith("[")) {
                              final closingBracketIdx = trimmed.indexOf("]");
                              if (closingBracketIdx != -1) {
                                category = trimmed.substring(
                                  1,
                                  closingBracketIdx,
                                );
                                bodyText = trimmed
                                    .substring(closingBracketIdx + 1)
                                    .trim();
                              }
                            }

                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(AppPadding.medium),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundWhite,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.borderGrey,
                                  width: 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.toUpperCase(),
                                    // Modified: Increased observation label size
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: AppPadding.tight),
                                  Text(
                                    bodyText,
                                    // Modified: Increased body text size
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
