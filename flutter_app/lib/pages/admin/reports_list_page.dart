import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../design/style_constant.dart';

class ReportsListPage extends StatefulWidget {
  const ReportsListPage({super.key});

  @override
  State<ReportsListPage> createState() => _ReportsListPageState();
}

class _ReportsListPageState extends State<ReportsListPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;
  DateTimeRange? selectedRange;
  String? selectedCategory;
  String? selectedTitle;

  bool sortAscending = false; 

  final List<String> categories = [
    'Work At Height',
    'Confined Space Work',
    'Chemical Hazard',
  ];
  final List<String> titles = [
    'Ladder',
    'Personnel Lifter',
    'Scaffold',
    'Liquid Nitrogen (LN2) Transportation',
    'Liquid Nitrogen (LN2) Refilling',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    setState(() => isLoading = true);

    try {
      // Include the foreign key join to load audit safety variables
      String selectQuery = '*, swp_templates!inner(id, category, title), WAH_safetyVariables_FK(*)';
      PostgrestFilterBuilder query = supabase
          .from('safety_reports')
          .select(selectQuery);

      if (selectedRange != null) {
        query = query
            .gte('submitted_at', selectedRange!.start.toIso8601String())
            .lte(
              'submitted_at',
              selectedRange!.end.add(const Duration(days: 1)).toIso8601String(),
            );
      }

      // Filter by SWP Template Category
      if (selectedCategory != null) {
        query = query.eq('swp_templates.category', selectedCategory!);
      }

      // Filter by SWP Template Title
      if (selectedTitle != null) {
        query = query.eq('swp_templates.title', selectedTitle!);
      }

      final response = await query.order('submitted_at', ascending: sortAscending);
      setState(() {
        reports = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Determines the theme color from a compliance status string
  Color _getColorFromRawString(String status) {
    final upper = status.toUpperCase();
    if (upper.contains('PARTIALLY')) {
      return Colors.orange;
    } else if (upper.contains('COMPLIANT') || upper.contains('SAFE')) {
      return Colors.green;
    } else if (upper.contains('NON') || upper.contains('DANGEROUS') || upper.contains('RISK')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  // Parses safety JSON map/string fields into structured reason strings
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
        final compliance = data['compliance'] ?? 'UNKNOWN';
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
    parseCategory("AREA HAZARDS", safetyVar['areaHazards']);

    return reasons;
  }

  Widget _reportCard(Map<String, dynamic> report) {
    final String techName = report['technician_name'] ?? 'Unknown Technician';
    final String details = report['Details'] ?? 'No details provided';
    final String date = report['submitted_at'] ?? '';
    final String department = report['department'] ?? 'N/A';
    final String SafetyProcedure = report['swp_templates']['category'] ?? 'N/A';
    final String SafetyProcedure_category = report['swp_templates']['title'] ?? 'N/A';
    final String designation = report["designation"] ?? 'N/A';
    final String permit_Number = report['wah_permit_numbers'] ?? "";
    final String location = report['location'] ?? 'No location';

    // Safely extract the safety variables object if present
    final safetyVar = report['WAH_safetyVariables_FK'];

    return Container(
      margin: const EdgeInsets.only(top: AppPadding.medium),
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderGrey.withAlpha(75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$techName: $SafetyProcedure | $SafetyProcedure_category",
            style: AppTypography.Blacksubheading,
          ),
          const SizedBox(height: AppPadding.medium),
          _buildInfoRow(Icons.location_on_outlined, location),
          const SizedBox(height: AppPadding.tight),
          _buildInfoRow(Icons.person, "Designation: $designation"),
          const SizedBox(height: AppPadding.tight),
          _buildInfoRow(Icons.business_outlined, "Department: $department"),
          if ((permit_Number.trim().isNotEmpty)) ...[
            const SizedBox(height: AppPadding.tight),
            _buildInfoRow(Icons.badge_outlined, "Ptw Number: $permit_Number"),
          ],
          const SizedBox(height: AppPadding.tight),
          _buildInfoRow(Icons.calendar_today, date),
          const SizedBox(height: AppPadding.tight),
          
          Container(
            color: AppColors.primaryTint,
            child: ExpansionTile(
              title: const Text('Details', style: AppTypography.body),
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    child: Text(details, style: AppTypography.body),
                  ),
                ),
              ],
            ),
          ),

          // Dropdown section for AI Safety Audit if safety variables foreign key is not null
          if (safetyVar != null) ...[
            const SizedBox(height: AppPadding.tight),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.borderGrey.withAlpha(75)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            (safetyVar['Overall Status'] ?? '').toString().toUpperCase().contains('DANGEROUS') ||
                                    (safetyVar['Overall Status'] ?? '').toString().toUpperCase().contains('NON')
                                ? Icons.report_problem_rounded
                                : Icons.assignment_turned_in_rounded,
                            color: _getColorFromRawString(safetyVar['Overall Status'] ?? 'UNKNOWN'),
                            size: 20,
                          ),
                          const SizedBox(width: AppPadding.tight),
                          const Text(
                            "AI Safety Audit",
                            style: AppTypography.body,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getColorFromRawString(safetyVar['Overall Status'] ?? 'UNKNOWN').withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _getColorFromRawString(safetyVar['Overall Status'] ?? 'UNKNOWN'), width: 1),
                        ),
                        child: Text(
                          (safetyVar['Overall Status'] ?? 'UNKNOWN').toString().toUpperCase(),
                          style: TextStyle(
                            color: _getColorFromRawString(safetyVar['Overall Status'] ?? 'UNKNOWN'),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppPadding.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildReasonsList(safetyVar).map((reason) {
                          final String trimmed = reason.trim();
                          if (trimmed.isEmpty) return const SizedBox.shrink();

                          final String upperReason = trimmed.toUpperCase();

                          final bool isRecommendation = trimmed.startsWith("Recommendation:") || 
                              upperReason.startsWith("• ADVICE:") || 
                              upperReason.contains("ADVICE:");

                          final bool isCategoryHeader = !trimmed.startsWith("•") && 
                              !trimmed.startsWith("[") && 
                              !isRecommendation && 
                              trimmed.contains(":") &&
                              (upperReason.contains("COMPLIANT") || upperReason.contains("DANGEROUS") || upperReason.contains("SAFE"));

                          final bool isBulletDetail = trimmed.startsWith("•") || 
                              upperReason.startsWith("DESCRIPTION:") || 
                              upperReason.startsWith("REASONING:");

                          if (isCategoryHeader) {
                            final parts = trimmed.split(":");
                            final String categoryName = parts[0].trim();
                            final String complianceStatus = parts.length > 1 ? parts[1].trim() : "UNKNOWN";
                            final Color subStatusColor = _getColorFromRawString(complianceStatus);

                            return Padding(
                              padding: const EdgeInsets.only(top: AppPadding.medium, bottom: AppPadding.tight),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    categoryName.toUpperCase(),
                                    style: AppTypography.body.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: subStatusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
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
                            );
                          } else if (isRecommendation) {
                            String adviceText = trimmed;
                            if (adviceText.startsWith("Recommendation:")) {
                              adviceText = adviceText.replaceFirst("Recommendation:", "").trim();
                            } else if (adviceText.startsWith("•")) {
                              String temp = adviceText.substring(1).trim();
                              if (temp.toUpperCase().startsWith("ADVICE:")) {
                                adviceText = temp.substring(7).trim();
                              } else {
                                adviceText = temp;
                              }
                            } else if (adviceText.toUpperCase().startsWith("ADVICE:")) {
                              adviceText = adviceText.substring(7).trim();
                            }
                            
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8, top: 4),
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
                                      color: Colors.black87,
                                      fontSize: 12,
                                      height: 1.4,
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
                              padding: const EdgeInsets.only(left: 6, bottom: 6, right: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("• ", style: TextStyle(color: Colors.black45, fontSize: 12)),
                                  Expanded(
                                    child: Text(
                                      bodyText,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 12,
                                        height: 1.4,
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
                                category = trimmed.substring(1, closingBracketIdx);
                                bodyText = trimmed.substring(closingBracketIdx + 1).trim();
                              }
                            }

                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(AppPadding.medium),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundWhite,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.borderGrey, width: 0.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.toUpperCase(),
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
                                    style: const TextStyle(
                                      color: Colors.black87,
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
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: AppPadding.medium, color: AppColors.primaryBlue),
        const SizedBox(width: AppPadding.tight),
        Expanded(child: Text(text, style: AppTypography.body)),
      ],
    );
  }

  void _showFilterDialog() async {
    DateTimeRange? tempRange = selectedRange;
    String? tempCategory = selectedCategory;
    String? tempTitle = selectedTitle;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Filter Reports',
                style: AppTypography.Bluesubheading,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: AppTypography.Blacksubheading.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppPadding.tight),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: tempRange,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => tempRange = picked);
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        tempRange == null
                            ? 'Select Date Range'
                            : '${tempRange?.start.toString().split(' ')[0]} to ${tempRange?.end.toString().split(' ')[0]}',
                      ),
                    ),
                    const SizedBox(height: AppPadding.medium),

                    Text(
                      'Category',
                      style: AppTypography.Blacksubheading.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: tempCategory,
                      hint: const Text('All Categories'),
                      items: categories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() => tempCategory = newValue);
                      },
                    ),
                    const SizedBox(height: AppPadding.tight),

                    Text(
                      'Title',
                      style: AppTypography.Blacksubheading.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: tempTitle,
                      hint: const Text('All Titles'),
                      items: titles.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() => tempTitle = newValue);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      tempRange = null;
                      tempCategory = null;
                      tempTitle = null;
                    });
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedRange = tempRange;
                      selectedCategory = tempCategory;
                      selectedTitle = tempTitle;
                    });
                    Navigator.pop(context);
                    loadReports();
                  },
                  child: const Text('Apply Filters'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFiltering =
        selectedRange != null ||
        selectedCategory != null ||
        selectedTitle != null;
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.page),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 31,
                      color: Colors.black,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'All Reports',
                        style: AppTypography.Bluesubheading,
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.swap_vert_rounded,
                      color: Colors.black,
                    ),
                    tooltip: sortAscending ? 'Showing Oldest First' : 'Showing Newest First',
                    onPressed: () {
                      setState(() {
                        sortAscending = !sortAscending;
                      });
                      loadReports();
                    },
                  ),

                  IconButton(
                    icon: Icon(
                      Icons.filter_list_alt,
                      color: isFiltering ? AppColors.primaryBlue : Colors.black,
                    ),
                    onPressed: _showFilterDialog,
                  ),

                  if (isFiltering)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          selectedRange = null;
                          selectedCategory = null;
                          selectedTitle = null;
                        });
                        loadReports();
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppPadding.Largest),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : reports.isEmpty
                    ? const Center(child: Text('No reports found'))
                    : ListView.builder(
                        itemCount: reports.length,
                        itemBuilder: (context, index) =>
                            _reportCard(reports[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}