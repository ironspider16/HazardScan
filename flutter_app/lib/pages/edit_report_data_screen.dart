import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

class EditReportDataScreen extends StatefulWidget {
  final Map<String, dynamic> initialAiData;

  const EditReportDataScreen({super.key, required this.initialAiData});

  @override
  State<EditReportDataScreen> createState() => _EditReportDataScreenState();
}

class _EditReportDataScreenState extends State<EditReportDataScreen> {
  // Valid compliance values — PARTIALLY COMPLIANT and COMPLIANT removed
  static const List<String> _validStatuses = ['SAFE', 'DANGEROUS', 'N/A'];

  // Only the technician's added text is stored here — original AI text is read-only
  final Map<String, TextEditingController> _additionControllers = {};
  late String _overallStatus;

  final List<Map<String, String>> _categories = [
    {'key': 'ladderHeight',        'label': 'Working at Heights'},
    {'key': 'ppe',                  'label': 'Personal Protective Equipment (PPE)'},
    {'key': 'buddySystem',          'label': 'Buddy System'},
    {'key': 'electricalMachinery',  'label': 'Electrical & Machinery Hazards'},
    {'key': 'areaHazards',          'label': 'Housekeeping and Area Hazards'},
  ];

  @override
  void initState() {
    super.initState();

    final raw = widget.initialAiData['overallStatus']?.toString().toUpperCase() ?? 'N/A';
    _overallStatus = _validStatuses.contains(raw) ? raw : 'N/A';

    // One free-text controller per category for the technician's added remarks
    for (final cat in _categories) {
      _additionControllers[cat['key']!] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _additionControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // Returns original AI text for a given category and field
  String _aiField(String categoryKey, String field) {
    final block = widget.initialAiData[categoryKey];
    if (block is Map) {
      return block[field]?.toString().trim() ?? '';
    }
    return '';
  }

  // Builds the updated map passed back to the technician page
  void _saveChanges() {
    final Map<String, dynamic> updatedData = {
      'overallStatus': _overallStatus,
    };

    for (final cat in _categories) {
      final key   = cat['key']!;
      final block = widget.initialAiData[key];
      final Map<String, dynamic> original =
          block is Map ? Map<String, dynamic>.from(block) : {};

      final String addedText = _additionControllers[key]!.text.trim();

      // Append technician addition to description and reasoning if provided
      // Advice field is preserved as-is from AI — never modified
      updatedData[key] = {
        'compliance':  original['compliance'] ?? 'N/A',
        'description': addedText.isEmpty
            ? (original['description'] ?? '')
            : '${original['description'] ?? ''}\n\n(EDIT: $addedText)',
        'reasoning':   original['reasoning'] ?? '',
        'advice':      original['advice'] ?? '',
      };
    }

    Navigator.pop(context, updatedData);
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'DANGEROUS': return Colors.red.shade700;
      case 'SAFE':      return Colors.green.shade700;
      default:          return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Add Remarks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveChanges,
            icon: const Icon(Icons.check, color: Colors.white, size: 18),
            label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Overall Status ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.medium, vertical: AppPadding.tight),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                border: Border.all(color: AppColors.borderGrey),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Overall Status',
                      style: AppTypography.body
                          .copyWith(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _overallStatus,
                    underline: const SizedBox.shrink(),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                    items: _validStatuses.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s,
                            style: TextStyle(
                                color: _statusColor(s),
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _overallStatus = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppPadding.medium),

            // ── Info notice ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppPadding.tight),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade300),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.amber.shade800, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI observations are read-only. Use the addition field to append your remarks.',
                      style: AppTypography.body.copyWith(
                          fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppPadding.medium),

            // ── Category cards ──────────────────────────────────────────────
            ..._categories.map((cat) {
              final key   = cat['key']!;
              final label = cat['label']!;

              final String aiDescription = _aiField(key, 'description');
              final String aiReasoning   = _aiField(key, 'reasoning');
              final String compliance    =
                  _aiField(key, 'compliance').toUpperCase();
              final Color badgeColor     = _statusColor(compliance);

              return Container(
                margin: const EdgeInsets.only(bottom: AppPadding.medium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.borderGrey),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Card header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.medium,
                          vertical: AppPadding.tight),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(20),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppDimensions.radiusSmall),
                          topRight: Radius.circular(AppDimensions.radiusSmall),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(label,
                                style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withAlpha(25),
                              border: Border.all(color: badgeColor, width: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              compliance.isEmpty ? 'N/A' : compliance,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // AI Observation (read-only)
                    if (aiDescription.isNotEmpty) ...[
                      _readOnlyField('Observation', aiDescription),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    ],

                    // AI Reasoning (read-only)
                    if (aiReasoning.isNotEmpty) ...[
                      _readOnlyField('Reasoning', aiReasoning),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    ],

                    // Technician addition field (editable)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppPadding.medium,
                          AppPadding.tight,
                          AppPadding.medium,
                          AppPadding.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Remarks (optional)',
                            style: AppTypography.body.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _additionControllers[key],
                            maxLines: null,
                            style: AppTypography.body,
                            decoration: InputDecoration(
                              hintText: 'Add your observations here...',
                              hintStyle: AppTypography.body.copyWith(
                                  color: Colors.grey.shade400),
                              filled: true,
                              fillColor: AppColors.backgroundWhite,
                              contentPadding: const EdgeInsets.all(AppPadding.tight),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall),
                                borderSide:
                                    BorderSide(color: AppColors.borderGrey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall),
                                borderSide:
                                    BorderSide(color: AppColors.borderGrey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall),
                                borderSide: BorderSide(
                                    color: AppColors.primaryBlue, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppPadding.medium),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.medium, vertical: AppPadding.tight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: AppTypography.body.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.body.copyWith(
                    fontSize: 12, color: AppColors.textMain, height: 1.5)),
          ),
        ],
      ),
    );
  }
}