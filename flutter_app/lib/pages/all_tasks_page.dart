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
          swp_templates: safe_work_procedure (
            category,
            title
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
    final List assignments = task['task_assignments'] ?? [];

    final List<String> techNames = assignments.map((a) {
      final account = a['accounts'];
      if (account == null) return 'Unknown Technician';
      return (account['name'] ?? account['email'] ?? 'Unknown').toString();
      }).toList();

    final String displayNames = techNames.isEmpty
      ? 'Unassigned'
      : techNames.join(', ');

      final swp = task['swp_templates'];
      String swpDisplay = task['task_type'] ?? 'General Task';

      if (swp != null) {
        final String category = swp['category'] ?? '';
        final String title = swp['title'] ?? '';
        swpDisplay += ' | $category - $title';
      }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.grey.shade200, // Matches your input borders
        ),
      ),
 

      child: Row(
        children: [
          // 🔵 Premium gradient circle (same size, upgraded look)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
            color: const Color.fromARGB(26, 37, 100, 235),
            borderRadius: BorderRadius.circular(12),
          ),

            child: const Icon(Icons.assignment, size: 30, color: Color(0xFF2563EB)),
          ),

          const SizedBox(width: 16),

          // 📄 Content (UNCHANGED)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🆔 PRIMARY ID: Bold and larger to act as the header
                Text(
                  task['workorder_id']?.toUpperCase() ?? 'NO ID',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700, // Extra bold for hierarchy
                    color: Color(0xFF1E293B),    // Darker slate for better contrast
                  ),
                ),
                const SizedBox(height: 12),

                // 🛠 TASK TYPE: Using a subtle "tag" style or icon
                _buildInfoRow(Icons.settings_outlined, swpDisplay),
                
                const SizedBox(height: 8),

                // 📍 LOCATION
                _buildInfoRow(Icons.location_on_outlined, task['location'] ?? 'Remote / Field'),

                const SizedBox(height: 8),

                // 👥 ASSIGNED TECHS: Slightly different color to distinguish from task info
                _buildInfoRow(
                  Icons.people_alt_outlined, 
                  displayNames, 
                  textColor: Colors.blueGrey.shade600,
                ),
              ],
            ),
          ),


          // 🎯 Buttons (UNCHANGED style, just cleaner border feel)
          Column(
            children: [
              SizedBox(
                width: 150,
                height: 34,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color.fromARGB(255, 103, 103, 103),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Edit Task',
                    style: TextStyle(color: Color.fromARGB(255, 87, 87, 87)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 150,
                height: 34,
                child: OutlinedButton(
                  onPressed: () => deleteTask(task['id']),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color.fromARGB(255, 251, 69, 69),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Delete Task',
                    style: TextStyle(color: Color.fromARGB(255, 251, 69, 69)),
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
    children: [
      Icon(icon, size: 16, color: const Color(0xFF2563EB).withOpacity(0.7)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: textColor ?? Colors.grey.shade700,
            fontWeight: FontWeight.w500,
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

              Row(
                children: [
                  _tabButton('Ongoing Tasks', 'Assigned'),
                  const SizedBox(width: 15),
                  _tabButton('Completed Tasks', 'Completed'),
                  const Spacer(),
                  const Icon(Icons.filter_alt_outlined, size: 20),
                  const SizedBox(width: 5),
                  const Text('All Filter', style: TextStyle(fontSize: 20)),
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
