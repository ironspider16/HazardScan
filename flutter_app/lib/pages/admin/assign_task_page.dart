import 'package:flutter/material.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kkhazardscan/pages/camera_page.dart';
import '../../widgets/Menu_button.dart';
import '../../widgets/App_Textfield.dart';
import '../../Design/style_constant.dart';

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

  // Safe work procedure template data
  List<Map<String, dynamic>> swpTemplates = [];
  List<String> selectedSWPIds = [];
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
    loadTechnicians();
    loadSWPTemplates();
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
    try {
      final response = await supabase
          .from('swp_templates')
          .select('id, category, title')
          .order('category', ascending: true);

      setState(() {
        swpTemplates = List<Map<String, dynamic>>.from(response);
        isLoadingSWPs = false;
      });
    } catch (e) {
      setState(() => isLoadingSWPs = false);
    }
  }

  Future<void> assignTask() async {
    if (selectedTechnicianIds.isEmpty ||
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
      final taskResponse = await supabase
          .from('tasks')
          .insert({
            'status': 'Assigned',
            'location': locationCtrl.text,
            'workorder_id': workOrderCtrl.text,
            'task_type': selectedTaskType,
            'task_details': detailsCtrl.text,
          })
          .select()
          .single();

      final newTaskId = taskResponse['id'];

      final techAssignment = selectedTechnicianIds
          .map(
            (techId) => {
              'task_id': newTaskId,
              'technician_id': int.parse(techId),
            },
          )
          .toList();

      await supabase.from('task_assignments').insert(techAssignment);

      if (selectedSWPIds.isNotEmpty) {
        final swpAssignment = selectedSWPIds
            .map(
              (swpId) => {
                'task_id': newTaskId,
                'swp_template_id': int.parse(swpId),
              },
            )
            .toList();

        await supabase.from('task_swp_assignments').insert(swpAssignment);
      }

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

  Widget _technicianMultiSelect() {
    if (isLoadingTechs) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigning Technicians',
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppPadding.tight),
        GestureDetector(
          onTap: () => _showTechSelectionDialog(),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person_add_alt_1_outlined, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            child: Text(
              selectedTechnicianIds.isEmpty
                  ? 'Select technicians'
                  : '${selectedTechnicianIds.length} selected',
              style: TextStyle(
                color: selectedTechnicianIds.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.textMain,
              ),
            ),
          ),
        ),

        // Optional: Show "Chips" for selected names below the button
        if (selectedTechnicianIds.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: selectedTechnicianIds.map((id) {
              final tech = technicians.firstWhere(
                (t) => t['id'].toString() == id,
              );
              return Chip(
                label: Text(
                  tech['name'] ?? tech['email'],
                  style: AppTypography.body.copyWith(fontSize: 12),
                ),
                backgroundColor: AppColors.primaryTint,
                deleteIconColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                  side: const BorderSide(
                    color: Colors.transparent,
                  ), // Removes the default border
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
        return StatefulBuilder(
          // Important to allow checkboxes to update inside dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.backgroundWhite,
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
                      activeColor: AppColors.primaryBlue,
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
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                  child: const Text("Done"),
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
        Text(
          "Task Type",
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppPadding.tight),
        DropdownButtonFormField<String>(
          initialValue:
              selectedTaskType, // Use 'value' instead of initialValue for better state tracking
          // 1. ADD THIS: This styles the text BEFORE a selection is made
          hint: Text(
            'Select type',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),

          // 2. This styles the text AFTER a selection is made
          style: AppTypography.body.copyWith(color: AppColors.textMain),

          decoration: const InputDecoration(
            // Leave hintText empty here if you are using the 'hint' property above
            // to avoid double-rendering or layout shifts.
            prefixIcon: Icon(Icons.category_outlined, size: 20),
          ),

          items: taskTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type,
                style: AppTypography.body,
              ), // Ensure items match body style
            );
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
        Text(
          'Safe Work Procedures',
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppPadding.tight),
        GestureDetector(
          onTap: () => _showSWPSelectionDialog(),
          child: InputDecorator(
            decoration: InputDecoration(
              // Use prefixIcon to match the AppTextField look
              prefixIcon: const Icon(Icons.list_alt_outlined, size: 20),
              // We use the contentPadding to match your other fields
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            child: Text(
              selectedSWPIds.isEmpty
                  ? 'Select SWP templates' // This acts as your "hint"
                  : '${selectedSWPIds.length} procedures selected',
              style: AppTypography.body.copyWith(
                // Match hint color logic
                color: selectedSWPIds.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.textMain,
              ),
            ),
          ),
        ),
        //label: Text('${swp['category']}: ${swp['title']}',
        if (selectedSWPIds.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: selectedSWPIds.map((id) {
              final swp = swpTemplates.firstWhere(
                (s) => s['id'].toString() == id,
              );
              return Chip(
                label: Text(
                  '${swp['category']}: ${swp['title']}',
                  style: AppTypography.body.copyWith(fontSize: 12),
                ),
                backgroundColor: AppColors.primaryTint,
                deleteIconColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                  side: const BorderSide(
                    color: Colors.transparent,
                  ), // Removes the default border
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
              backgroundColor: AppColors.backgroundWhite,
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
                      activeColor: AppColors.primaryBlue,
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
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.backgroundWhite,
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildResponsiveRow({
    required bool isMobile,
    required List<Widget> children,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }
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
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 420;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.page),
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
                              style: AppTypography.Bluesubheading,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppPadding.Largest),

                    // Row 1
                    _buildResponsiveRow(
                      isMobile: isMobile,
                      children: [
                        isMobile
                            ? _technicianMultiSelect()
                            : Expanded(child: _technicianMultiSelect()),
                        SizedBox(
                          width: isMobile ? 0 : AppPadding.medium,
                          height: isMobile ? AppPadding.medium : 0,
                        ),
                        isMobile
                            ? AppTextfield(
                                label: 'Location',
                                hint: 'Ward 2B → Bed 12',
                                controller: locationCtrl,
                                prefixIcon: Icons.location_on_outlined,
                              )
                            : Expanded(
                                child: AppTextfield(
                                  label: 'Location',
                                  hint: 'Ward 2B → Bed 12',
                                  controller: locationCtrl,
                                  prefixIcon: Icons.location_on_outlined,
                                ),
                              ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Row 2
                    _buildResponsiveRow(
                      isMobile: isMobile,
                      children: [
                        isMobile
                            ? AppTextfield(
                                label: 'Work Order ID',
                                hint: 'WO-xxxx',
                                controller: workOrderCtrl,
                                prefixIcon: Icons.badge_outlined,
                              )
                            : Expanded(
                                child: AppTextfield(
                                  label: 'Work Order ID',
                                  hint: 'WO-xxxx',
                                  controller: workOrderCtrl,
                                  prefixIcon: Icons.badge_outlined,
                                ),
                              ),
                        SizedBox(
                          width: isMobile ? 0 : AppPadding.medium,
                          height: isMobile ? AppPadding.medium : 0,
                        ),
                        isMobile
                            ? _taskTypeDropdown()
                            : Expanded(child: _taskTypeDropdown()),
                      ],
                    ),

                    const SizedBox(height: AppPadding.large),

                    _swpMultiSelect(),

                    const SizedBox(height: AppPadding.large),

                    AppTextfield(
                      label: 'Work Task Activity Details',
                      hint: 'Describe task...',
                      Maxlines: 4,
                      controller: detailsCtrl,
                    ),

                    const SizedBox(height: AppPadding.large),

                    SizedBox(
                      width: double.infinity,
                      child: MenuButton(
                        label: "Assign",
                        onTap: isSubmitting ? () {} : assignTask,
                        isPrimary: true,
                        icon: isSubmitting ? Icons.hourglass_empty : Icons.task,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
