import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kkhazardscan/Design/status_Colors.dart';
import 'package:kkhazardscan/pages/admin/reports_detail_page.dart';
import 'package:kkhazardscan/services/report_compiler.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import 'package:kkhazardscan/widgets/Menu_button.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../design/style_constant.dart';

class ReportsListPage extends StatefulWidget {
  const ReportsListPage({super.key});

  @override
  State<ReportsListPage> createState() => _ReportsListPageState();
}

class _ReportsListPageState extends State<ReportsListPage> {
  final supabase = Supabase.instance.client;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;
  DateTimeRange? selectedRange;
  String? selectedCategory;
  String? selectedTitle;
  String? selectedComplianceLevel;

  bool sortAscending = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _allGroups = [];
  List<int> _selectedReports = [];
  PersistentBottomSheetController? _bottomSheetController;
  bool get _isSelectionMode => _selectedReports.isNotEmpty;
  bool selectEmailGroupStep = false;

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

  final List<String> complianceLevels = [
    'SAFE',
    'COMPLIANT',
    'PARTIALLY COMPLIANT',
    'DANGEROUS',
  ];

  @override
  void initState() {
    super.initState();
    loadReports();
    _fetchAllGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredReports {
    if (_searchQuery.trim().isEmpty) {
      return reports;
    }
    final query = _searchQuery.trim().toLowerCase();
    return reports.where((report) {
      final String techName = (report['technician_name'] ?? '')
          .toString()
          .toLowerCase();
      final String details = (report['Details'] ?? '').toString().toLowerCase();
      final String department = (report['department'] ?? '')
          .toString()
          .toLowerCase();
      final String designation = (report['designation'] ?? '')
          .toString()
          .toLowerCase();
      final String permitNumber = (report['wah_permit_numbers'] ?? '')
          .toString()
          .toLowerCase();
      final String location = (report['location'] ?? '')
          .toString()
          .toLowerCase();
      final swpTemplate = report['swp_templates'];
      final String templateCategory = swpTemplate != null
          ? (swpTemplate['category'] ?? '').toString().toLowerCase()
          : '';
      final String templateTitle = swpTemplate != null
          ? (swpTemplate['title'] ?? '').toString().toLowerCase()
          : '';
      final safetyVar = report['WAH_safetyVariables_FK'];
      final String overallStatus = safetyVar != null
          ? (safetyVar['Overall Status'] ?? '').toString().toLowerCase()
          : '';
      return techName.contains(query) ||
          details.contains(query) ||
          department.contains(query) ||
          designation.contains(query) ||
          permitNumber.contains(query) ||
          location.contains(query) ||
          templateCategory.contains(query) ||
          templateTitle.contains(query) ||
          overallStatus.contains(query);
    }).toList();
  }

  Future<void> loadReports() async {
    setState(() => isLoading = true);

    try {
      // Include the foreign key join to load audit safety variables
      String complianceJoinModifier = selectedComplianceLevel != null
          ? '!inner'
          : '';

      String selectQuery =
          '*, swp_templates!inner(id, category, title), WAH_safetyVariables_FK$complianceJoinModifier(*)';

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

      if (selectedComplianceLevel != null) {
        query = query.eq('swp_templates.category', 'Work At Height');
        query = query.eq(
          'WAH_safetyVariables_FK.Overall Status',
          selectedComplianceLevel!,
        );
      }

      final response = await query.order(
        'submitted_at',
        ascending: sortAscending,
      );
      setState(() {
        reports = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAllGroups() async {
    try {
      final data = await supabase
          .from("email_groups")
          .select("id, name")
          .order('name', ascending: true);
      setState(() {
        _allGroups = (data as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (e) {
      debugPrint("Error fetching groups : $e");
    }
  }

  void _handleRowTap(int id) {
    _toggleSelection(id);
  }

  // Change individual row selection status with tactile haptic feedback
  void _toggleSelection(int id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedReports.contains(id)) {
        _selectedReports.remove(id);
      } else {
        _selectedReports.add(id);
      }
    });

    _bottomSheetController?.setState?.call(() {});
  }

  // Cancel multi-select state safely
  void _clearSelection() {
    setState(() {
      _selectedReports.clear();
    });
    _bottomSheetController?.setState?.call(() {});
  }

  void _conditionalCloseBottomSheet() {
    if (_selectedReports.isEmpty) {
      _bottomSheetController?.close();
    }
  }

  // Parses safety JSON map/string fields into structured reason strings

  Widget _informationChips(Map<String, Map<String, dynamic>> info) {
    return Wrap(
      spacing: AppPadding.tight,
      runSpacing: AppPadding.tight,
      children: [
        Chip(
          label: Text(
            info["location"]?["string"] as String? ?? "Unknown location",
          ),
          backgroundColor: const Color.fromARGB(66, 255, 255, 255),
          avatar: Icon(info["location"]?["icon"] as IconData),
          side: const BorderSide(
            style: BorderStyle.none,
            color: Colors.transparent,
          ),
        ),
        Chip(
          label: Text(info["date"]?["string"] as String? ?? "Unknown date"),
          avatar: Icon(info["date"]?["icon"] as IconData),
          side: const BorderSide(
            style: BorderStyle.none,
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }

  Widget _reportCard(Map<String, dynamic> report) {
    final int reportId = report['id'];
    final bool isSelected = _selectedReports.contains(reportId);

    final String techName = report['technician_name'] ?? 'Unknown Technician';
    final String date = report['submitted_at'] ?? '';
    final String safetyProcedure =
        report['swp_templates']?['category'] ?? 'N/A';
    final String safetyProcedureCategory =
        report['swp_templates']?['title'] ?? 'N/A';
    final String location = report['location'] ?? 'No location';
    final safetyVar = report['WAH_safetyVariables_FK'];

    // Extract compliance status to color-code the card's edge
    final String overallStatus = safetyVar?['Overall Status'] ?? 'UNKNOWN';
    final Color statusColor = SafetyStatusHelper.getColor(overallStatus);

    Map<String, Map<String, dynamic>> info = {
      "location": {"string": location, "icon": Icons.location_on_outlined},
      "date": {"string": date, "icon": Icons.calendar_month_outlined},
    };

    return Container(
      margin: const EdgeInsets.only(top: AppPadding.medium),

      // Clip contents so the splash effect stays inside the border radius
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: InkWell(
          onLongPress: () => {
            _toggleSelection(reportId),
            _openBottomSheet(context),
          },
          onTap: () {
            if (_isSelectionMode) {
              _handleRowTap(reportId);
              _conditionalCloseBottomSheet();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportsDetailPage(report: report),
                ),
              );
            }
          },
          child: Stack(
            children: [
              Container(
                color: AppColors.primaryTint,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // A subtle status indicator bar on the far left edge of the card
                      Container(width: 6, color: statusColor),

                      // Main card details content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppPadding.medium),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "$safetyProcedure — $safetyProcedureCategory",
                                      style:
                                          AppTypography
                                              .Blacksubheading.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? (Icons.check_circle)
                                        : Icons.chevron_right_rounded,
                                    color: isSelected
                                        ? AppColors.primaryBlue
                                        : Colors.black.withOpacity(0.35),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppPadding.tight / 2),

                              Text(
                                "Submitted by: $techName",
                                style: AppTypography.faintbody.copyWith(
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: AppPadding.medium),
                              _informationChips(info),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isSelected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMedium,
                        ),
                        border: Border.all(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() async {
    DateTimeRange? tempRange = selectedRange;
    String? tempCategory = selectedCategory;
    String? tempTitle = selectedTitle;
    String? tempComplianceLevel = selectedComplianceLevel;

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
                    Text(
                      'Compliance Level',
                      style: AppTypography.Blacksubheading.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: tempComplianceLevel,
                      hint: const Text('All Levels'),
                      items: complianceLevels.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() => tempComplianceLevel = newValue);
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
                      tempComplianceLevel = null;
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
                MenuButton(
                  label: 'Apply Filters',
                  isPrimary: true,
                  width:
                      120, // Set a fixed width that fits the dialog action area
                  height: 40,
                  onTap: () {
                    setState(() {
                      selectedRange = tempRange;
                      selectedCategory = tempCategory;
                      selectedTitle = tempTitle;
                      selectedComplianceLevel = tempComplianceLevel;
                    });
                    Navigator.pop(context);
                    loadReports();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openBottomSheet(BuildContext context) {
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState == null) return;

    _bottomSheetController = scaffoldState.showBottomSheet(
      (BuildContext ctx) {
        // 2. Wrap with StatefulBuilder to handle bottom sheet internal updates
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: const EdgeInsets.only(top: AppPadding.tight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (selectEmailGroupStep == false) ...[
                    SizedBox(
                      height: AppPadding.Largest,
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          debugPrint(_selectedReports.toString());
                          // 3. Use setSheetState to trigger a rebuild of the sheet
                          setSheetState(() {
                            selectEmailGroupStep = true;
                          });
                        },
                        style: TextButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.email, size: AppPadding.medium),
                            SizedBox(width: AppPadding.tight),
                            Text(
                              'Send to email group (${_selectedReports.length} selected)',
                              style: TextStyle(fontSize: AppPadding.medium),
                            ),
                            SizedBox(width: AppPadding.tight),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppPadding.tight),
                  ] else ...[
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        itemCount: _allGroups.length,
                        itemBuilder: (context, index) {
                          final int groupId = _allGroups[index]["id"];
                          final String groupName = _allGroups[index]["name"];
                          return SizedBox(
                            height: AppPadding.Largest,
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _sendReportsToEmailGroup(groupId, groupName);
                              },
                              style: TextButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(width: AppPadding.Largest),
                                  Text(
                                    'Send to ${_allGroups[index]["name"]}',
                                    style: TextStyle(
                                      fontSize: AppPadding.medium,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.send),
                                  SizedBox(width: AppPadding.Largest),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const Divider(height: 1, thickness: 1),

                  SizedBox(
                    height: AppPadding.Largest,
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: () {
                        _clearSelection();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Close',
                        style: AppTypography.faintbody,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppPadding.tight),
        ),
      ),
    );

    _bottomSheetController?.closed.then((_) {
      _bottomSheetController = null;
      // 4. Reset the step variable when the sheet is closed completely
      setState(() {
        selectEmailGroupStep = false;
      });
    });
  }

  Future<void> _sendReportsToEmailGroup(int groupId, String groupName) async {
    final selectedObjs = reports
        .where((r) => _selectedReports.contains(r['id']))
        .toList();
    // List map string dynamic of selected reports based on id

    if (selectedObjs.isEmpty) return;

    // Show non-dismissible loading dialog during PDF generation and network requests
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppPadding.tight),
        ),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: AppPadding.large),
              Text(
                "Sending ${selectedObjs.length} reports to $groupName...",
                style: AppTypography.body,
              ),
            ],
          ),
        );
      },
    );

    int successCount = 0;

    for (int i = 0; i < selectedObjs.length; i++) {
      final report = selectedObjs[i];
      try {
        // Reconstruct the nested AI data map from flat database columns
        final safetyVar =
            report['WAH_safetyVariables_FK'] as Map<String, dynamic>?;
        final Map<String, dynamic> aiData = {
          'overallStatus': safetyVar?['Overall Status'] ?? 'PENDING',
          'ladderHeight':
              safetyVar?['ladderheight'] ??
              {'status': 'N/A', 'notes': 'No AI evaluation available'},
          'ppe':
              safetyVar?['ppe'] ??
              {'status': 'N/A', 'notes': 'No AI evaluation available'},
          'buddySystem':
              safetyVar?['buddySystem'] ??
              {'status': 'N/A', 'notes': 'No AI evaluation available'},
          'areaHazards':
              safetyVar?['areaHazards'] ??
              {'status': 'N/A', 'notes': 'No AI evaluation available'},
        };

        // Compile PDF locally without image evidence
        final Uint8List pdfBytes = await LocalReportCompiler.generateWshReport(
          location: report['location']?.toString() ?? 'Not Declared',
          supervisor: report['technician_name']?.toString() ?? 'Unassigned',
          employer: report['department']?.toString() ?? 'Not Declared',
          initialAiData: aiData,
          manualNotes: report['Details']?.toString() ?? '',
          imagesBytes: null,
          submittedAt: report['submitted_at'],
        );

        final String base64Pdf = base64Encode(pdfBytes);

        // Invoke Supabase Edge Function for each report
        final response = await supabase.functions.invoke(
          'email-sending',
          body: {
            "group_id": groupId,
            "technician_name": report['technician_name'] ?? 'Unassigned',
            "details": report['Details'] ?? '',
            "title": report['swp_templates']?['title'] ?? 'General',
            "category": report['swp_templates']?['category'] ?? 'General',
            "ptw_number": report['wah_permit_numbers'] ?? '',
            "designation": report['designation'] ?? '',
            "department": report['department'] ?? '',
            "location": report['location'] ?? '',
            "pdf": base64Pdf,
          },
        );

        if (response.status == 200 || response.status == 201) {
          successCount++;
        } else {
          debugPrint('Failed to send report ${report['id']}: ${response.data}');
        }
      } catch (e) {
        debugPrint('Error dispatching report ${report['id']}: $e');
      }
    }

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Successfully sent $successCount of ${selectedObjs.length} reports to $groupName.",
        ),
        backgroundColor: successCount == selectedObjs.length
            ? Colors.green
            : Colors.orange,
      ),
    );

    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFiltering =
        selectedRange != null ||
        selectedCategory != null ||
        selectedTitle != null ||
        selectedComplianceLevel != null;

    final filteredData = _filteredReports;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(
        title: _isSelectionMode
            ? "All Reports (${_selectedReports.length} Selected) "
            : "All Reports",
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_vert_rounded, color: Colors.black),
            tooltip: sortAscending
                ? 'Showing Oldest First'
                : 'Showing Newest First',
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
                  selectedComplianceLevel = null;
                });
                loadReports();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Column(
            children: [
              const SizedBox(height: AppPadding.tight),
              AppTextfield(
                label: "reports",
                islabel: false,
                hint: 'Search location, department, name...',
                controller: _searchController,
                prefixIcon: Icons.search,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredData.isEmpty
                    ? const Center(child: Text('No reports found'))
                    : ListView.builder(
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) =>
                            _reportCard(filteredData[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
