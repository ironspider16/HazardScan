import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/status_Colors.dart';
import 'package:kkhazardscan/pages/admin/reports_detail_page.dart';
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

  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;
  DateTimeRange? selectedRange;
  String? selectedCategory;
  String? selectedTitle;
  String? selectedComplianceLevel;

  bool sortAscending = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      // Clip contents so the splash effect stays inside the border radius
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportsDetailPage(report: report),
              ),
            );
          },
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "$safetyProcedure — $safetyProcedureCategory",
                                style: AppTypography.Blacksubheading.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.black.withOpacity(0.35),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppPadding.tight / 2),

                        Text(
                          "Submitted by: $techName",
                          style: AppTypography.faintbody.copyWith(fontSize: 13),
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

  @override
  Widget build(BuildContext context) {
    final bool isFiltering =
        selectedRange != null ||
        selectedCategory != null ||
        selectedTitle != null ||
        selectedComplianceLevel != null;

    final filteredData = _filteredReports;
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(
        title: "All Reports",
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
