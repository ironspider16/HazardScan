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
          .select()
          .eq('status', selectedStatus)
          .order('id', ascending: false);

      final accountResponse = await supabase
          .from('accounts')
          .select('id, email');

      final Map<int, String> emails = {};

      for (final acc in accountResponse) {
        emails[acc['id']] = acc['email'];
      }

      setState(() {
        tasks = List<Map<String, dynamic>>.from(taskResponse);
        technicianEmails = emails;
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
    final int technicianId = task['technician_id'];
    final String email = technicianEmails[technicianId] ?? 'Unknown technician';

    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF8FAFF), // light blue
            Color.fromARGB(255, 218, 227, 255), // light purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color.fromARGB(255, 195, 195, 195).withOpacity(0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            blurRadius: 6,
            offset: const Offset(-2, -2),
          ),
        ],
      ),

      child: Row(
        children: [
          // 🔵 Premium gradient circle (same size, upgraded look)
          Container(
            width: 115,
            height: 150,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment, size: 62, color: Colors.white),
          ),

          const SizedBox(width: 22),

          // 📄 Content (UNCHANGED)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['workorder_id'] ?? '',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 14),
                Text(
                  task['task_type'] ?? '',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  task['location'] ?? '',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 18),
                Text(email, style: const TextStyle(fontSize: 18)),
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
