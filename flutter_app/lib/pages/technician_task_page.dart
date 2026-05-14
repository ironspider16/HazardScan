import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:kkhazardscan/config/app_users.dart';
import 'package:kkhazardscan/pages/technician_swp_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/Menu_button.dart';

class TechnicianTaskPage extends StatefulWidget {
  final AppUser user;
  const TechnicianTaskPage({super.key, required this.user});

  @override
  State<TechnicianTaskPage> createState() => _TechnicianTaskPageState();
}

class _TechnicianTaskPageState extends State<TechnicianTaskPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;
  String selectedStatus = 'Assigned';

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() => isLoading = true);

    try {
      final assignedTaskData = await supabase
          .from('task_assignments')
          .select('task_id')
          .eq('technician_id', widget.user.id);

      final List<int> myTaskIds = List<int>.from(
        assignedTaskData.map((row) => row['task_id']),
      );

      if (myTaskIds.isEmpty) {
        setState(() {
          tasks = [];
          isLoading = false;
        });
        return;
      }

      final taskResponse = await supabase
          .from('tasks')
          .select('''
            *,
            task_swp_assignments (
               swp_templates (
                id,
                category,
                title
              )
            ),
            task_assignments (
              accounts (id, name, email)
            )
          ''')
          .inFilter('id', myTaskIds)
          .eq('status', selectedStatus)
          .order('id', ascending: false);

      setState(() {
        tasks = List<Map<String, dynamic>>.from(taskResponse);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading tasks: $e')));
    }
  }

    Widget _tabButton(String text, String status) {
    final bool selected = selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStatus = status;
        });
        loadTasks();
      },
      child: Row(
        children: [
          Text(
            text,
            style: AppTypography.Blacksubheading.copyWith(
              color: selected ? null : AppColors.textSecondary,
            ),
          ),

          // ONLY show count when this tab is selected
          if (selected) ...[
            const SizedBox(width: AppPadding.tight),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.tight),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                color: AppColors.primaryTint,
              ),
              child: Text(
                tasks.length.toString(),
                style: (AppTypography.Blacksubheading.copyWith(height: 1.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    double screenwidth = MediaQuery.of(context).size.width;
    bool showIcon = screenwidth > 420;

    final List assignments = task['task_assignments'] ?? [];
    final List<String> techNames = assignments.map((a) {
      final account = a['accounts'];
      if (account == null) return 'Unknown Technician';
      return (account['name'] ?? account['email'] ?? 'Unknown').toString();
    }).toList();

    final String displayNames = techNames.isEmpty
        ? 'Unassigned'
        : techNames.join(', ');
    final List swpAssignments = task['task_swp_assignments'] ?? [];

    final List<String> swpTitles = swpAssignments.map((assignment) {
      final template = assignment['swp_templates'];
      if (template == null) return 'Unknown Template';
      return '${template['category']} - ${template['title']}';
    }).toList();

    String swpDisplay = task['task_type'] ?? 'General Task';
    if (swpTitles.isNotEmpty) {
      swpDisplay += ' | ${swpTitles.join(' · ')}';
    }

    final String details =
        task['task_details'] ?? 'No additional details provided.';

    return Container(
      margin: const EdgeInsets.only(top: AppPadding.medium),
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderGrey.withAlpha(75)),
      ),
      child: Column(
        // Changed to Column to allow vertical stacking
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showIcon) ...[
                // Icon Box
                Container(
                  width:
                      AppPadding.Largest +
                      AppPadding.tight, // Reduced slightly for better fit
                  height: AppPadding.Largest + AppPadding.tight,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    size: AppPadding.large,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
              const SizedBox(width: AppPadding.medium),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['workorder_id']?.toUpperCase() ?? 'NO ID',
                      style: AppTypography.Blacksubheading,
                    ),
                    const SizedBox(height: AppPadding.tight),
                    _buildInfoRow(Icons.settings_outlined, swpDisplay),
                    const SizedBox(height: AppPadding.tight),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      task['location'] ?? 'Field',
                    ),
                    const SizedBox(height: AppPadding.tight),
                    _buildInfoRow(Icons.people_alt_outlined, displayNames),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppPadding.medium),
            child: Divider(height: 1), // Optional: adds a nice separator
          ),

          // Actions
          MenuButton(
            label: selectedStatus == 'Assigned'
                ? 'View Details'
                : 'View Report',
            onTap: () => _showDetailsDialog(details),
            isPrimary: false,
            icon: Icons.remove_red_eye_sharp,
          ),
          const SizedBox(height: AppPadding.medium),
          Row(
            children: [
              Expanded(
                child: MenuButton(
                  label: selectedStatus == 'Assigned'
                      ? 'Complete SWP'
                      : 'View Report',
                  onTap: selectedStatus == 'Assigned'
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TechnicianSWPPage(task: task),
                          ),
                        )
                      : () {},
                  isPrimary: true,
                  icon: Icons.checklist_outlined,
                  isMini: true,
                ),
              ),
              const SizedBox(width: AppPadding.tight),
              Expanded(
                child: MenuButton(
                  label: selectedStatus == 'Assigned'
                      ? 'Complete Task'
                      : 'View Report',
                  onTap: selectedStatus == 'Assigned' ? () {} : () {},
                  isPrimary: true,
                  icon: Icons.check,
                  isMini: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppPadding.tight / 4),
          child: Icon(
            icon,
            size: AppPadding.medium,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: AppPadding.tight),
        Expanded(child: Text(text, style: AppTypography.body)),
      ],
    );
  }

  void _showDetailsDialog(String details) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundWhite,
          title: const Text(
            "Task details",
            style: AppTypography.Blacksubheading,
          ),
          content: SingleChildScrollView(
            child: Text(
              details,
              style: AppTypography.body
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 18, 30, 20),
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
                        'My Tasks',
                        style: AppTypography.Bluesubheading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 31),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth:
                              MediaQuery.of(context).size.width -
                              (AppPadding.page * 2),
                        ),
                        // We give the scaling box a "target" width of the screen
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceBetween, // Pushes items to opposite sides
                          children: [
                            // Left Side: Tab Buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _tabButton('Ongoing', 'Assigned'),
                                const SizedBox(width: AppPadding.medium),
                                _tabButton('Completed', 'Completed'),
                              ],
                            ),

                            const SizedBox(width: AppPadding.medium),

                            // Right Side: Filter Button
                            GestureDetector(
                              onTap: () => print("Filter tapped"),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.filter_alt_outlined,
                                    size: AppPadding.medium,
                                  ),
                                  SizedBox(width: AppPadding.medium / 4),
                                  Text(
                                    'Filter',
                                    style: AppTypography.Blacksubheading,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : tasks.isEmpty
                    ? Center(
                        child: Text(
                          selectedStatus == 'Assigned'
                              ? 'You have no ongoing tasks'
                              : 'You have no completed tasks',
                        ),
                      )
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) =>
                            _taskCard(tasks[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
