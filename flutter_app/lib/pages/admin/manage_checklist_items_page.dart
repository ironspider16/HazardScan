import 'package:flutter/material.dart';
import 'package:kkhazardscan/supabase_client.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import '../../widgets/Menu_button.dart';

class ManageChecklistItemsPage extends StatefulWidget {
  final int categoryId;
  const ManageChecklistItemsPage({super.key, required this.categoryId});

  @override
  State<ManageChecklistItemsPage> createState() =>
      _ManageChecklistItemsPageState();
}

class _ManageChecklistItemsPageState extends State<ManageChecklistItemsPage> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  // 1. Get data from Supabase
  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('swp_items')
          .select()
          .eq('template_id', widget.categoryId)
          .order('id', ascending: true);
      setState(() => _items = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error fetching checklist items: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load. Please try again.")),
        );
      }
      setState(() => _isLoading = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Open adaptive dialog to handle both Adding and Editing actions
  Future<void> _showChecklistDialog({Map<String, dynamic>? itemToEdit}) async {
    final bool isEdit = itemToEdit != null;
    final TextEditingController controller = TextEditingController(
      text: isEdit ? itemToEdit['description'] : '',
    );

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Text(
          isEdit ? "Edit Item" : "Add Item",
          style: AppTypography.Blackheading.copyWith(fontSize: 22),
        ),
        content: AppTextfield(
          label: '',
          islabel: false,
          hint: "Enter Checklist Item name",
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
                  height: 44,
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
      final String input = controller.text.trim();
      setState(() => _isLoading = true);

      try {
        if (isEdit) {
          // Update database entry matching the original name context
          await supabase
              .from('swp_items')
              .update({'description': input})
              .eq('id', itemToEdit['id']);
        } else {
          // Insert completely new entry row
          await supabase.from('swp_items').insert({
            'description': input,
            'template_id': widget.categoryId,
          });
        }
        _fetchItems();
      } catch (e) {
        debugPrint("Error processing database query: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save. Please try again.")),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. Delete Logic
  Future<void> _confirmDelete(Map<String, dynamic> itemToDelete) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Text(
          "Delete Checklist Item?",
          style: AppTypography.Blackheading.copyWith(
            fontSize: 24,
            color: Colors.red,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this checklist item?",
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
      try {
        await supabase.from('swp_items').delete().eq('id', itemToDelete['id']);
        _fetchItems(); // Refresh list
      } catch (e) {
        debugPrint("Error processing database query: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete. Please try again.")),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(title: "Manage Checklist Items"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.page),
              child: Column(
                children: [
                  const SizedBox(height: AppPadding.medium),
                  // List of checklist items
                  Expanded(
                    child: ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppPadding.tight),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _ItemRow(
                          description:
                              item['description'] ?? 'Empty description',
                          onEdit: () => _showChecklistDialog(itemToEdit: item),
                          onDelete: () => _confirmDelete(item),
                        );
                      },
                    ),
                  ),

                  const Divider(
                    height: AppPadding.large,
                    thickness: 1,
                    color: Color(0xFFE0E0E0),
                  ),

                  // Add checklist item Button
                  _AddCheckListItem(onTap: () => _showChecklistDialog()),
                  const SizedBox(height: AppPadding.medium),
                ],
              ),
            ),
    );
  }
}

// Custom Row Widget based on Figma
class _ItemRow extends StatelessWidget {
  final String description;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemRow({
    required this.description,
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
          Expanded(child: Text(description, style: AppTypography.body)),
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

// Custom Add checklist item Button Widget
class _AddCheckListItem extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCheckListItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MenuButton(
      label: "Add Checklist Item",
      icon: Icons.checklist,
      onTap: onTap,
      // Custom styling for the button
    );
  }
}
