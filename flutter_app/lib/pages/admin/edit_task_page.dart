import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/admin/all_tasks_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditTaskPage extends StatefulWidget {
  final Map<String, dynamic> task; // Optional: Pass existing task data for editing
  const EditTaskPage({super.key, required this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final supabase = Supabase.instance.client;

  // Controllers
  final locationCtrl = TextEditingController();
  final workOrderCtrl = TextEditingController();
  final detailsCtrl = TextEditingController();

  // Safe work procedure template data
  List<Map<String, dynamic>> swpTemplates = [];
  List<String>  selectedSWPIds = [];
  bool isLoadingSWPs = true;

  // Technician data
  List<Map<String, dynamic>> technicians = [];
  List<String> selectedTechnicianIds = [];

  String? selectedTaskType;

  bool isLoadingTechs = true;
  bool isSubmitting = false;

  final List<String> taskTypes = [
    'Electrical',
    'Plumbing',
    'Maintenance',
    'Repair',
    'Inspection',
  ];

  @override
  void initState() {
    super.initState();
    // prefill
    locationCtrl.text = widget.task['location'] ?? '';
    workOrderCtrl.text = widget.task['workorder_id'] ?? '';
    detailsCtrl.text = widget.task['task_details'] ?? '';
    selectedTaskType = widget.task['task_type'];

    _loadAllData();
  }

  Future<void> loadTechnicians() async {
    try {
      final response = await supabase
          .from('accounts') // 🔥 change if your table name different
          .select('id, email, name')
          .eq('role', 'Technician');

      setState(() {
        technicians = List<Map<String, dynamic>>.from(response);
        isLoadingTechs = false;
      });
    } catch (e) {
      setState(() => isLoadingTechs = false);
    }
  }

  Future<void> loadSWPTemplates() async {
    try{
      final response = await supabase
        .from('swp_templates')
        .select('id, category, title')
        .order('category', ascending: true);

        setState(() {
          swpTemplates = List<Map<String, dynamic>>.from(response);
          isLoadingSWPs = false;
        }
        );
    }
    catch (e) {
      setState(() => isLoadingSWPs = false);
    }

  }

  Future<void> _loadCurrentAssignments() async {

    try{
      final techData = await supabase
        .from('task_assignments')
        .select('technician_id')
        .eq('task_id', widget.task?['id']);

      final swpData = await supabase
        .from('task_swp_assignments')
        .select('swp_template_id')
        .eq('task_id', widget.task?['id']);
      
      setState(() {
        selectedTechnicianIds = techData.map((t) => t['technician_id'].toString()).toList();
        selectedSWPIds = swpData.map((s) => s['swp_template_id'].toString()).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading assignments: $e')),
      );
    }
  }
  Future<void> _loadAllData() async {
  await Future.wait([
    loadTechnicians(),
    loadSWPTemplates(),
    _loadCurrentAssignments(), // New method below
  ]);
}


  Future<void> assignTask() async {
    if (selectedTechnicianIds.isEmpty||
        locationCtrl.text.isEmpty ||
        workOrderCtrl.text.isEmpty ||
        selectedTaskType == null ||
        detailsCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }



    setState(() => isSubmitting = true);
    final taskId = widget.task?['id'];

   try {
      await supabase.from('tasks').update({
        'location': locationCtrl.text,
        'workorder_id': workOrderCtrl.text,
        'task_type': selectedTaskType,
        'task_details': detailsCtrl.text,
      }).eq('id', taskId);

      await supabase.from('task_assignments').delete().eq('task_id', taskId);
      final techAssignment = selectedTechnicianIds.map((techId) => {
            'task_id': taskId,
            'technician_id': int.parse(techId),
          }).toList();

      await supabase.from('task_assignments').insert(techAssignment);

      await supabase.from('task_swp_assignments').delete().eq('task_id', taskId);

      if (selectedSWPIds.isNotEmpty) {
        final swpAssignment = selectedSWPIds.map((swpId) => {
              'task_id': taskId,
              'swp_template_id': int.parse(swpId),
            }).toList();

        await supabase.from('task_swp_assignments').insert(swpAssignment);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task edited successfully')),
      );

      Navigator.pop(context, true); // Go back after saving

    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => isSubmitting = false);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Color(0xFF555555)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _technicianMultiSelect() {
    if (isLoadingTechs) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Assigning Technicians'),
        GestureDetector(
          onTap:() => _showTechSelectionDialog(),
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFF555555)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedTechnicianIds.isEmpty
                      ? 'Select technicians'
                      : '${selectedTechnicianIds.length} selected',
                  style: TextStyle(
                    color: selectedTechnicianIds.isEmpty ? const Color(0xFF9E9E9E) : Colors.black,
                  ),
                ),
              ),
              const Icon(Icons.person_add_outlined, size: 20),
            ],
          ),
        ),
      ),
      // Optional: Show "Chips" for selected names below the button
      if (selectedTechnicianIds.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: selectedTechnicianIds.map((id) {
            final tech = technicians.firstWhere((t) => t['id'].toString() == id);
            return Chip(
              label: Text(tech['name'] ?? tech['email'], style: const TextStyle(fontSize: 12, color: Colors.black54)),
              backgroundColor: Color.fromARGB(22, 37, 100, 235),
              deleteIconColor: Colors.red,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.transparent), // Removes the default border
            ),
              onDeleted: () {
                setState(() => selectedTechnicianIds.remove(id));
              },
            );
          }).toList(),
        ),
      ],
    ],
  );
}

void _showTechSelectionDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder( // Important to allow checkboxes to update inside dialog
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Color.fromARGB(255, 235, 237, 242),
            title: const Text("Select Technicians"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: technicians.length,
                itemBuilder: (ctx, index) {
                  final tech = technicians[index];
                  final id = tech['id'].toString();
                  final isSelected = selectedTechnicianIds.contains(id);

                  return CheckboxListTile(
                    title: Text(tech['name'] ?? tech['email']),
                    activeColor: const Color(0xFF2563EB),
                    value: isSelected,
                    onChanged: (bool? checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selectedTechnicianIds.add(id);
                        } else {
                          selectedTechnicianIds.remove(id);
                        }
                      });
                      // Update the main page UI as well
                      setState(() {});
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                
                style: TextButton.styleFrom(
                  foregroundColor:Colors.white,
                  backgroundColor: const Color(0xFF2563EB)
                ),
                child: const Text("Done")
              ),
            ],
          );
        },
      );
    },
  );
}

  Widget _taskTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Task Type'),
        DropdownButtonFormField<String>(
          value: selectedTaskType,
          decoration: _inputDecoration('Select type'),
          items: taskTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedTaskType = value;
            });
          },
        ),
      ],
    );
  }

  Widget _swpMultiSelect() {
  if (isLoadingSWPs) return const Center(child: CircularProgressIndicator());

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Safe Work Procedures'),
      GestureDetector(
        onTap: () => _showSWPSelectionDialog(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFF555555)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedSWPIds.isEmpty
                      ? 'Select SWP templates'
                      : '${selectedSWPIds.length} procedures selected',
                  style: TextStyle(
                    color: selectedSWPIds.isEmpty ? const Color(0xFF9E9E9E) : Colors.black,
                  ),
                ),
              ),
              const Icon(Icons.list_alt_outlined, size: 20),
            ],
          ),
        ),
      ),
      //label: Text('${swp['category']}: ${swp['title']}', 
      if (selectedSWPIds.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: selectedSWPIds.map((id) {
            final swp = swpTemplates.firstWhere((s) => s['id'].toString() == id);
            return Chip(
              label: Text('${swp['category']}: ${swp['title']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              backgroundColor: Color.fromARGB(22, 37, 100, 235),
              deleteIconColor: Colors.red,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.transparent), // Removes the default border
            ),
              onDeleted: () {
                setState(() => selectedSWPIds.remove(id));
              },
            );
          }).toList(),
        ),
      ],
    ],
  );
}

void _showSWPSelectionDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Color.fromARGB(255, 235, 237, 242),
            title: const Text("Select SWP Templates"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: swpTemplates.length,
                itemBuilder: (ctx, index) {
                  final swp = swpTemplates[index];
                  final id = swp['id'].toString();
                  final isSelected = selectedSWPIds.contains(id);

                  return CheckboxListTile(
                    title: Text(swp['category']),
                    subtitle: Text(swp['title']),
                    activeColor: const Color(0xFF2563EB),
                    value: isSelected,
                    onChanged: (bool? checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selectedSWPIds.add(id);
                        } else {
                          selectedSWPIds.remove(id);
                        }
                      });
                      setState(() {});
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Done"),
                style: TextButton.styleFrom(
                  foregroundColor:Colors.white,
                  backgroundColor: const Color(0xFF2563EB)
                ),
              ),
            ],
          );
        },
      );
    },
  );
}


  @override
  void dispose() {
    locationCtrl.dispose();
    workOrderCtrl.dispose();
    detailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding (
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Edit Task',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),

              const SizedBox(height: 40),

              // Row 1
              Row(
                children: [
                  Expanded(child: _technicianMultiSelect()),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _textField(
                      label: 'Location',
                      hint: 'Ward 2B → Bed 12',
                      controller: locationCtrl,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Row 2
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      label: 'Work Order ID',
                      hint: 'WO-xxxx',
                      controller: workOrderCtrl,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: _taskTypeDropdown()),
                ],
              ),

              const SizedBox(height: 25),

              _swpMultiSelect(),

              const SizedBox(height: 25),

              _textField(
                label: 'Work Task Activity Details',
                hint: 'Describe task...',
                controller: detailsCtrl,
                maxLines: 4,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : assignTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), // blue button
                    foregroundColor: Colors.white, // ✅ text = white
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes')
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
