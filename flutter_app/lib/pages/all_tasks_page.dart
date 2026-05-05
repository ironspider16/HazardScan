import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
            style: TextStyle(
              fontSize: 20,
              color: selected
                  ? Color.fromARGB(255, 0, 119, 255)
                  : const Color.fromARGB(255, 68, 68, 68),
            ),
          ),

          // ONLY show count when this tab is selected
          if (selected) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tasks.length.toString(),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {

    double screenwidth = MediaQuery.of(context).size.width;
    bool showIcon = screenwidth > 380; // Show icon only on wider screens
    final List assignments = task['task_assignments'] ?? [];
    final List<String> techNames = assignments.map((a) {
      final account = a['accounts'];
      if (account == null) return 'Unknown Technician';
      return (account['name'] ?? account['email'] ?? 'Unknown').toString();
    }).toList();

    final String displayNames = techNames.isEmpty ? 'Unassigned' : techNames.join(', ');
    final List swpAssignments = task['task_swp_assignments'] ?? [];
    
    final List<String> swpTitles = swpAssignments.map((assignment) {
    final template = assignment['swp_templates'];
    if (template == null) return 'Unknown Template';
    return '${template['category']} - ${template['title']}';
    }).toList();
    
    String swpDisplay = task['task_type'] ?? 'General Task';

    if (swpTitles.isNotEmpty) {
      swpDisplay += ' | ' + swpTitles.join(' · ');
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column( // Changed to Column to allow vertical stacking
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showIcon) ...[
              // Icon Box
              Container(
                width: 50, // Reduced slightly for better fit
                height: 50,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(26, 37, 100, 235),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment, size: 24, color: Color(0xFF2563EB)),
              ),
              ],
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['workorder_id']?.toUpperCase() ?? 'NO ID',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.settings_outlined, swpDisplay),
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.location_on_outlined, task['location'] ?? 'Field'),
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.people_alt_outlined, displayNames, 
                        textColor: Colors.blueGrey.shade600),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1), // Optional: adds a nice separator
          ),
          // Action Buttons - Now Full Width at the bottom
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Edit', style: TextStyle(color: Colors.black54)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => deleteTask(task['id']),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(icon, size: 16, color: const Color(0xFF2563EB).withOpacity(0.7)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: textColor ?? Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    final int ongoingCount = selectedStatus == 'Assigned' ? tasks.length : 0;

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
                        'All Tasks',
                        style: TextStyle(fontSize: 17, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 31),
                ],
              ),

              const SizedBox(height: 85),

              // Inside build() -> Column -> children:
              Row(
                children: [
                  Expanded( // Wrap tabs in Expanded + FittedBox
                    child: FittedBox(
                      fit: BoxFit.scaleDown, // This shrinks the text if it's too wide
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          _tabButton('Ongoing Tasks', 'Assigned'),
                          const SizedBox(width: 15),
                          _tabButton('Completed Tasks', 'Completed'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter Button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.filter_alt_outlined, size: 18),
                      SizedBox(width: 4),
                      Text('Filter', style: TextStyle(fontSize: 16)), // Slightly smaller font
                    ],
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
