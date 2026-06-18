import 'package:flutter/material.dart';
import 'package:kkhazardscan/supabase_client.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import '../../widgets/Menu_button.dart';

class ManageDepartmentsPage extends StatefulWidget {
  const ManageDepartmentsPage({super.key});

  @override
  State<ManageDepartmentsPage> createState() => _ManageDepartmentsPageState();
}

class _ManageDepartmentsPageState extends State<ManageDepartmentsPage> {
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  // 1. Get data from Supabase
  Future<void> _fetchDepartments() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('departments')
          .select()
          .order('department', ascending: true);
      setState(() => _departments = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error fetching departments: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Open adaptive dialog to handle both Adding and Editing actions
  Future<void> _showDepartmentDialog({
    Map<String, dynamic>? departmentToEdit,
  }) async {
    final bool isEdit = departmentToEdit != null;
    final TextEditingController controller = TextEditingController(
      text: isEdit ? departmentToEdit['department'] : '',
    );

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Text(
          isEdit ? "Edit Department" : "Add Department",
          style: AppTypography.Blackheading.copyWith(fontSize: 22),
        ),
        content: AppTextfield(
          label: '',
          islabel: false,
          hint: "Enter department name",
          controller: controller,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: MenuButton(
                  onTap: () => Navigator.pop(ctx, false),
                  label: "Cancel",
                  height: 44
                ),
              ),
              const SizedBox(width: AppPadding.tight),
              Expanded(
                child: MenuButton(
                  isPrimary: true,
                  onTap: () => Navigator.pop(ctx, true),
                  label: isEdit ? "Save" : "Add",
                  height: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Process implementation if confirmed and string data is not empty
    if (shouldSave == true && controller.text.trim().isNotEmpty) {
      final String inputName = controller.text.trim();
      setState(() => _isLoading = true);

      try {
        if (isEdit) {
          // Update database entry matching the original name context
          await supabase
              .from('departments')
              .update({'department': inputName})
              .eq('department', departmentToEdit['department']);
        } else {
          // Insert completely new entry row
          await supabase.from('departments').insert({'department': inputName});
        }
        _fetchDepartments();
      } catch (e) {
        debugPrint("Error processing database query: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. Delete Logic
  Future<void> _confirmDelete(Map<String, dynamic> department) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Text(
          "Delete Department?",
          style: AppTypography.Blackheading.copyWith(
            fontSize: 24,
            color: Colors.red,
          ),
        ),
        content: Text(
          "Are you sure you want to delete ${department['department']}?",
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: AppTypography.body),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Delete",
              style: AppTypography.body.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase
          .from('departments')
          .delete()
          .eq('department', department['department']);
      _fetchDepartments(); // Refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(title: "Manage Departments"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.page),
              child: Column(
                children: [
                  const SizedBox(height: AppPadding.medium),
                  // List of Departments
                  Expanded(
                    child: ListView.separated(
                      itemCount: _departments.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppPadding.tight),
                      itemBuilder: (context, index) {
                        final dept = _departments[index];
                        return _DepartmentRow(
                          department: dept['department'] ?? 'No Department',
                          onEdit: () =>
                              _showDepartmentDialog(departmentToEdit: dept),
                          onDelete: () => _confirmDelete(dept),
                        );
                      },
                    ),
                  ),

                  const Divider(
                    height: AppPadding.large,
                    thickness: 1,
                    color: Color(0xFFE0E0E0),
                  ),

                  // Add Departments Button
                  _AddDepartmentButton(onTap: () => _showDepartmentDialog()),
                  const SizedBox(height: AppPadding.medium),
                ],
              ),
            ),
    );
  }
}

// Custom Row Widget based on Figma
class _DepartmentRow extends StatelessWidget {
  final String department;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DepartmentRow({
    required this.department,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.medium,
        vertical: AppPadding.tight,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryTint, // Light blue tint
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        children: [
          Expanded(child: Text(department, style: AppTypography.body)),
          IconButton(
            icon: const Icon(Icons.edit_note, color: AppColors.textMain),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// Custom Add Department Button Widget
class _AddDepartmentButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddDepartmentButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MenuButton(
      label: "Add Department",
      icon: Icons.people,

      onTap: onTap,
      // Custom styling for the button
    );
  }
}
