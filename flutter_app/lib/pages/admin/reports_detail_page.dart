import 'dart:convert';
import 'package:flutter/material.dart';
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
  late final bool spreaderUnlocked;
  late final Map<String, dynamic>? initialAnalysisData;
  late final int totalAttempts;
  late final String? aiChangeAnalysis;
  late final bool isComparative;

  // Helper method to safely evaluate dynamic data to a boolean without throwing TypeErrors
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();

    // Safely parse safety_variables_FK in case it arrives as a JSON string instead of a map
    dynamic rawSafetyVar = widget.report['safety_variables_FK'];
    Map<String, dynamic> parsedSafetyVar = {};
    if (rawSafetyVar is Map) {
      parsedSafetyVar = Map<String, dynamic>.from(rawSafetyVar);
    } else if (rawSafetyVar is String) {
      try {
        parsedSafetyVar = Map<String, dynamic>.from(jsonDecode(rawSafetyVar));
      } catch (_) {}
    }
    safetyVar = parsedSafetyVar;

    // Directly assign properties without setState to prevent lifecycle issues
    location = widget.report['location']?.toString() ?? 'No location';
    designation = widget.report['designation']?.toString() ?? 'N/A';
    department = widget.report['department']?.toString() ?? 'N/A';
    details = widget.report['Details']?.toString() ?? 'No details provided';
    ptwNumber = widget.report['wah_permit_numbers']?.toString() ?? 'N/A';
    techName = widget.report['technician_name']?.toString() ?? 'N/A';
    date = widget.report['submitted_at']?.toString() ?? 'N/A';
    reportCode = widget.report['report_code']?.toString() ?? 'unknown ID';

    final swp = widget.report['swp_templates'];
    if (swp is Map) {
      category = "${swp['category']} - ${swp['title']}";
    } else {
      category = "N/A";
    }

    // Safely evaluate the boolean using the helper
    spreaderUnlocked = _parseBool(safetyVar['spreaderUnlocked']);
    dynamic rawInitialVar = widget.report['initialAnalysisId'];
    if (rawInitialVar is Map) {
      initialAnalysisData = Map<String, dynamic>.from(rawInitialVar);
    } else {
      initialAnalysisData = null;
    }
    totalAttempts = widget.report['totalAttempts'] as int? ?? 1;
    aiChangeAnalysis = widget.report['aiChangeAnalysis']?.toString() ?? '';
    isComparative = initialAnalysisData != null && totalAttempts > 1;
  }

  Color _statusColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'DANGEROUS':
        return Colors.red.shade700;
      case 'SAFE':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  Widget _complianceBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        status.isEmpty ? 'N/A' : status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // Status banner - mirrors PDF _statusBanner
  Widget _statusBanner(String status) {
    final color = _statusColor(status);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'FINAL CLOSURE COMPLIANCE STATUS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section header - blue left border
  Widget _sectionHeader(String title) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        border: Border(
          left: BorderSide(color: AppColors.primaryBlue, width: 4),
        ),
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Info grid - label/value table
  Widget _infoGrid(List<List<String>> rows) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(2)},
        children: rows
            .map(
              (row) => TableRow(
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Text(
                      row[0],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Text(row[1], style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  // Pass label
  Widget _passLabel(String text, Color color) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  // Category card - mirrors PDF _hazardCard
  Widget _categoryCard(String label, Map<String, dynamic> block) {
    final compliance = block['compliance']?.toString().toUpperCase() ?? 'N/A';
    final description = block['description']?.toString() ?? '';
    final reasoning = block['reasoning']?.toString() ?? '';
    final advice = block['advice']?.toString() ?? '';
    final color = _statusColor(compliance);

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGrey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // header: category name + badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                _complianceBadge(compliance),
              ],
            ),
          ),
          Divider(height: 1),
          // field rows
          _fieldRow('Observation', description),
          Divider(height: 1, color: Colors.grey.shade50),
          _fieldRow('Reasoning', reasoning),
          Divider(height: 1, color: Colors.grey.shade50),
          _fieldRow('Corrective Action', advice),
        ],
      ),
    );
  }

  Widget _fieldRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  // Evolution table row
  Widget _evolutionTable(
    Map<String, dynamic> initialData,
    Map<String, dynamic> finalData,
  ) {
    final categories = [
      ['Working at Heights', 'ladderheight'],
      ['Personal Protective Equipment', 'ppe'],
      ['Buddy System Requirements', 'buddySystem'],
      ['Electrical & Machinery Safeguards', 'electricalMachinery'],
      ['Housekeeping and Area Hazards', 'areaHazards'],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Table(
        border: TableBorder.all(color: AppColors.borderGrey, width: 0.5),
        columnWidths: const {0: FlexColumnWidth(1.6), 1: FlexColumnWidth(2.4)},
        children: [
          TableRow(
            decoration: BoxDecoration(color: AppColors.primaryBlue),
            children: [
              _tableCell('Safety Check Module', isHeader: true),
              _tableCell('Status Transformation', isHeader: true),
            ],
          ),
          ...categories.map((cat) {
            final before =
                (initialData[cat[1]] as Map<String, dynamic>?)?['compliance']
                    ?.toString()
                    .toUpperCase() ??
                'N/A';
            final after =
                (finalData[cat[1]] as Map<String, dynamic>?)?['compliance']
                    ?.toString()
                    .toUpperCase() ??
                'N/A';
            return TableRow(
              children: [
                _tableCell(cat[0]),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      _complianceBadge(before),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '->',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      _complianceBadge(after),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isHeader ? Colors.white : AppColors.textMain,
        ),
      ),
    );
  }

  List<Widget> _hazardCards(Map<String, dynamic> data) {
    final categories = [
      ['Working at Heights', 'ladderheight'],
      ['Personal Protective Equipment', 'ppe'],
      ['Buddy System Requirements', 'buddySystem'],
      ['Electrical & Machinery Safeguards', 'electricalMachinery'],
      ['Housekeeping and Area Hazards', 'areaHazards'],
    ];
    return categories.map((cat) {
      final block = data[cat[1]] as Map<String, dynamic>? ?? {};
      return _categoryCard(cat[0], block);
    }).toList();
  }

  // AI summary box
  Widget _aiSummaryBox(String text) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: AppColors.borderGrey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, height: 1.5)),
    );
  }

  // Image replacement notice
  Widget _imageNotice() {
    return Container(
      width:
          double.infinity, // Spans full width so left/right margins are equal
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: AppColors.borderGrey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
            CrossAxisAlignment.center, // Centers all children horizontally
        children: [
          Icon(Icons.email_outlined, color: AppColors.primaryBlue, size: 24),
          const SizedBox(height: 8),
          Text(
            'Report Code: $reportCode',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'The full inspection report including site photographs has been distributed to immediate email recipients. Request a copy using the report code above.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
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
    final String rawStatus = safetyVar['Overall Status'] ?? 'N/A';

    return Scaffold(
      appBar: const UniversalAppBar(title: 'Reports Detail Page'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              color: AppColors.primaryTint,
              surfaceTintColor: AppColors.primaryTint,
              margin: const EdgeInsets.fromLTRB(
                AppPadding.medium,
                AppPadding.medium,
                AppPadding.medium,
                AppPadding.tight,
              ),
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
                    _buildInfoRow(
                      Icons.loop,
                      'Rectification Attempts',
                      isComparative
                          ? '$totalAttempts attempt(s) required to achieve compliance'
                          : 'Site passed on first analysis',
                    ),
                    const SizedBox(height: AppPadding.tight),
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

            if ((aiChangeAnalysis ?? '').isNotEmpty) ...[
              _sectionHeader(
                isComparative
                    ? 'Rectification Summary (AI Insight)'
                    : 'First-Pass Compliance Notice',
              ),
              _aiSummaryBox(aiChangeAnalysis ?? ''),
            ],

            if (isComparative) ...[
              _sectionHeader('Metric Evolution'),
              _evolutionTable(initialAnalysisData!, safetyVar),
            ],

            if (spreaderUnlocked) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: Colors.red.shade700.withAlpha(26),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "LADDER'S SPREADER BAR UNLOCKED",
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            _sectionHeader(
              isComparative
                  ? 'Initial Inspection — Hazard Identification'
                  : 'Hazard Identification & Assessment',
            ),
            _passLabel(
              isComparative
                  ? 'INITIAL AUDIT PASS — UNSAFE STATE'
                  : 'SINGLE PASS — COMPLIANT STATE',
              isComparative ? Colors.red.shade700 : Colors.green.shade700,
            ),
            const SizedBox(height: 8),
            ..._hazardCards(isComparative ? initialAnalysisData! : safetyVar),

            if (isComparative) ...[
              _sectionHeader('Rectified Inspection — Verified Safe State'),
              _passLabel(
                'RECTIFIED AUDIT PASS — SAFE STATE',
                Colors.green.shade700,
              ),
              const SizedBox(height: 8),
              ..._hazardCards(safetyVar),
            ],

            _sectionHeader(
              isComparative ? 'Evidence Photography' : 'Evidence Photography',
            ),
            const SizedBox(height: 8),
            _imageNotice(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
