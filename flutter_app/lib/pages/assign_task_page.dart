import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignTaskPage extends StatefulWidget {
  const AssignTaskPage({super.key});

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final supabase = Supabase.instance.client;

  // Controllers
  final locationCtrl = TextEditingController();
  final workOrderCtrl = TextEditingController();
  final detailsCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();

  // Technician data
  List<Map<String, dynamic>> technicians = [];
  String? selectedTechnicianId;

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
    loadTechnicians();
  }

  Future<void> loadTechnicians() async {
    try {
      final response = await supabase
          .from('accounts') // 🔥 change if your table name different
          .select('id, email')
          .eq('role', 'Technician');

      setState(() {
        technicians = List<Map<String, dynamic>>.from(response);
        isLoadingTechs = false;
      });
    } catch (e) {
      setState(() => isLoadingTechs = false);
    }
  }

  Future<void> assignTask() async {
    if (selectedTechnicianId == null ||
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

    try {
      await supabase.from('tasks').insert({
        'technician_id': int.parse(selectedTechnicianId!),
        'status': 'Assigned',
        'location': locationCtrl.text,
        'workorder_id': workOrderCtrl.text,
        'task_type': selectedTaskType,
        'task_details': detailsCtrl.text,
        'remarks_notes': remarksCtrl.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task assigned successfully')),
      );

      Navigator.pop(context);
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

  Widget _technicianDropdown() {
    if (isLoadingTechs) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Assigning Technician'),
        DropdownButtonFormField<String>(
          value: selectedTechnicianId,
          decoration: _inputDecoration('Select technician'),
          items: technicians.map((tech) {
            return DropdownMenuItem(
              value: tech['id'].toString(),
              child: Text(tech['email']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedTechnicianId = value;
            });
          },
        ),
      ],
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

  @override
  void dispose() {
    locationCtrl.dispose();
    workOrderCtrl.dispose();
    detailsCtrl.dispose();
    remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
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
                        'Assign Tasks',
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
                  Expanded(child: _technicianDropdown()),
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

              _textField(
                label: 'Work Task Activity Details',
                hint: 'Describe task...',
                controller: detailsCtrl,
                maxLines: 4,
              ),

              const SizedBox(height: 25),

              _textField(
                label: 'Remarks/Notes',
                hint: 'Optional notes...',
                controller: remarksCtrl,
                maxLines: 4,
              ),

              const Spacer(),

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
                      : const Text('Assign'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
