import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_task_page.dart';
import '../../widgets/Menu_button.dart';
import '../../design/style_constant.dart';

class AllTasksPage extends StatefulWidget {
  const AllTasksPage({super.key});

  @override
  State<AllTasksPage> createState() => _AllTasksPageState();
}

class _AllTasksPageState extends State<AllTasksPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> tasks = [];
  Map<int, String> technicianEmails = {};

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
      final taskResponse = await supabase
          .from('tasks')
          .select('''
          *,
          task_swp_assignments (
             swp_templates (
              category,
              title
            )
          ),
          task_assignments (
            accounts (
              id,
              name,
              email
            )
          )
        ''')
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

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteTask(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteTask(int id) async {
    try {
      await supabase.from('tasks').delete().eq('id', id);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task deleted')));

      loadTasks();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete error: $e')));
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
    bool showIcon = screenwidth > 420; // Show icon only on wider screens
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
          // Action Buttons - Now Full Width at the bottom
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _goToEditTask(task),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmDelete(task['id']),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? textColor}) {
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

  void _goToEditTask(Map<String, dynamic> task) async {
    // Capture the result (the 'true' we sent in Navigator.pop)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTaskPage(task: task)),
    );

    // If the result is true, it means a task was edited successfully
    if (result == true) {
      loadTasks(); // Call your existing function that fetches tasks from Supabase
    }
  }

  @override
  Widget build(BuildContext context) {
    final int ongoingCount = selectedStatus == 'Assigned' ? tasks.length : 0;

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
                        'All Tasks',
                        style: AppTypography.Bluesubheading,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppPadding.Largest),

              // Inside build() -> Column -> children:
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
                                _tabButton('Ongoing Tasks', 'Assigned'),
                                const SizedBox(width: AppPadding.medium),
                                _tabButton('Completed Tasks', 'Completed'),
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
                              ? 'No ongoing tasks'
                              : 'No completed tasks',
                        ),
                      )
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return _taskCard(tasks[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
