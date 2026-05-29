import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../design/style_constant.dart';
import '../../widgets/Menu_button.dart';

class ReportsListPage extends StatefulWidget {
  const ReportsListPage({super.key});

  @override
  State<ReportsListPage> createState() => _ReportsListPageState();
}

class _ReportsListPageState extends State<ReportsListPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> reports = []; // Renamed from tasks
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
      String selectQuery = '*, swp_templates!inner(id, category, title)';
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

      // 3. Filter by SWP Template Category
      if (selectedCategory != null) {
        query = query.eq('swp_templates.category', selectedCategory!);
      }

      // 4. Filter by SWP Template Title
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

  Widget _reportCard(Map<String, dynamic> report) {
    final String techName = report['technician_name'] ?? 'Unknown Technician';
    final String details = report['Details'] ?? 'No details provided';
    final String date = report['submitted_at'] ?? '';
    final String department = report['department'] ?? 'N/A';
    final String SafetyProcedure = report['swp_templates']['category'] ?? 'N/A';
    final String SafetyProcedure_category =
        report['swp_templates']['title'] ?? 'N/A';
    final String designation = report["designation"] ?? 'N/A';
    final String permit_Number = report['wah_permit_numbers'] ?? "";
    final String location = report['location'] ?? 'No location';

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
    // Temporary variables to hold choices inside the dialog setup box
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
                    // --- DATE RANGE SECTION ---
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

                    // --- CATEGORY DROPDOWN ---
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

                    // --- TITLE DROPDOWN ---
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
                // Clear All Active Filter Values Button
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
                    // Save Dialog state back to Page state context
                    setState(() {
                      selectedRange = tempRange;
                      selectedCategory = tempCategory;
                      selectedTitle = tempTitle;
                    });
                    Navigator.pop(context);
                    loadReports(); // Fetch updated items
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
                    icon: Icon(
                      sortAscending ? Icons.swap_vert_rounded : Icons.swap_vert_rounded,
                      color: sortAscending ? AppColors.primaryBlue : Colors.black,
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
