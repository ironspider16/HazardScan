import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/app_users.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TechnicianTaskPage extends StatefulWidget {

  final AppUser user; // Pass the user object to this page
  const TechnicianTaskPage({super.key , required this.user});

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
        assignedTaskData.map((row) => row['task_id'])
    );



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
  bool showIcon = screenwidth > 380; 
  
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
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
      ],
    ),
    child: Column( // Changed main wrapper to Column
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showIcon) ...[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(26, 37, 100, 235),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment, size: 24, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 16),
            ],
            // Text Content - Now has full width minus icon
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
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
        // Action Button - Now full width at the bottom
        SizedBox(
          width: double.infinity, // Makes button fill the card width
          height: 40,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              selectedStatus == 'Assigned' ? 'View Details' : 'View Report',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildInfoRow(IconData icon, String text, {Color? textColor}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start, 
    children: [
      Padding(padding: const EdgeInsets.only(top:2),
      child:Icon(icon, size: 16, color: const Color(0xFF2563EB).withOpacity(0.7)),
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
                        'My Tasks',
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
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(children: [
                        _tabButton('Ongoing Tasks', 'Assigned'),
                        const SizedBox(width: 15),
                        _tabButton('Completed Tasks', 'Completed'),
                      ],
                     ),
                    ),
                  ),

                  const SizedBox(width:8,),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt_outlined, size: 18),
                      SizedBox(width: 4),
                      Text('Filter', style: TextStyle(fontSize: 16)),
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
                              ? 'You have no ongoing tasks'
                              : 'You have no completed tasks',
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
