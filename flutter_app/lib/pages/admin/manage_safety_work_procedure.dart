import 'package:flutter/material.dart';
import 'package:kkhazardscan/supabase_client.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import '../../widgets/Menu_button.dart';

class ManageSafetyWorkProcedurePage extends StatefulWidget {
  const ManageSafetyWorkProcedurePage({super.key});

  @override
  State<ManageSafetyWorkProcedurePage> createState() =>
      _ManageSafetyWorkProcedurePageState();
}

class _ManageSafetyWorkProcedurePageState
    extends State<ManageSafetyWorkProcedurePage> {
  List<Map<String, dynamic>> _swp = [];
  Set<String> categorySet = {};
  bool _isLoading = true;
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _fetchSwp();
  }

  // 1. Get data from Supabase
  Future<void> _fetchSwp() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('swp_templates')
          .select('id, category, title, requires_permit, is_active')
          .order('category', ascending: true);

      final flatList = List<Map<String, dynamic>>.from(data);
      final fetchedCategorySet = <String>{};

      final Map<String, List<Map<String, dynamic>>> tempMap = {};

      for (var row in flatList) {
        final String category = row['category'] ?? 'Uncategorized';

        final activity = {
          'id': row['id'],
          'name': row['title'],
          'requires_permit': row['requires_permit'],
          'is_active': row['is_active'],
        };

        tempMap.putIfAbsent(category, () => []).add(activity);
        // put if absent, inserts a key into the tempMap if kay is not there yet
        // Example: tempMap = {Chemical Hazard : [{activity map}, {2nd activity map}]
        // .add activity adds the specific title into that map
        fetchedCategorySet.add(category);
      }

      final groupedSwp = tempMap.entries.map((entry) {
        return {'category': entry.key, 'titles': entry.value};
      }).toList();

      setState(() {
        _swp = groupedSwp;
        categorySet = fetchedCategorySet;
      });
      debugPrint(_swp.toString());
    } catch (e) {
      debugPrint("Error fetching Safety Work Procedures: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editSwpDialog({
    required List<int> idsToEdit,
    required String name,
    required bool isCategory,
    required bool? requires_permit,
  }) async {
    // Initialize controller with the existing name for easier editing
    final TextEditingController controller = TextEditingController(text: name);

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            title: Text(
              "Edit $name",
              style: AppTypography.Blackheading.copyWith(fontSize: 22),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextfield(
                    label: '',
                    islabel: false,
                    hint: "Enter new name",
                    controller: controller,
                  ),
                  const SizedBox(height: AppPadding.tight),
                  if (!isCategory) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Requires Permit?",
                        style: AppTypography.body,
                      ),
                      value: requires_permit ?? false,
                      onChanged: (val) {
                        setDialogState(() => requires_permit = val);
                      },
                    ),
                  ],
                ],
              ),
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
                      label: "Save",
                      height: 44,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Process implementation if confirmed and string data is not empty
    if (shouldSave == true && controller.text.trim().isNotEmpty) {
      final String inputName = controller.text.trim();
      setState(() => _isLoading = true);

      try {
        if (isCategory) {
          await supabase
              .from('swp_templates')
              .update({'category': inputName})
              .filter(
                'id',
                'in',
                idsToEdit,
              ); // Use filter instead of eq for lists
        } else {
          await supabase
              .from('swp_templates')
              .update({'title': inputName, 'requires_permit': requires_permit})
              .filter(
                'id',
                'in',
                idsToEdit,
              ); // Use filter instead of eq for lists
        }
        _fetchSwp();
      } catch (e) {
        debugPrint("Error processing database query: $e");
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _showAddSwpDialog() async {
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    bool requiresPermit = false;

    try {
      final bool? shouldSave = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              title: Text(
                "Add SWP",
                style: AppTypography.Blackheading.copyWith(fontSize: 22),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextfield(
                      label: '',
                      islabel: false,
                      hint: "Enter or select SWP category name",
                      controller: categoryController,
                      suffixIcon: categorySet.isNotEmpty
                          ? PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.black,
                              ),
                              onSelected: (String value) {
                                categoryController.text = value;
                              },
                              itemBuilder: (BuildContext context) {
                                return categorySet.map((String option) {
                                  return PopupMenuItem<String>(
                                    value: option,
                                    child: Text(
                                      option,
                                      style: AppTypography.body,
                                    ),
                                  );
                                }).toList();
                              },
                            )
                          : null,
                    ),
                    const SizedBox(height: AppPadding.tight),
                    AppTextfield(
                      label: '',
                      islabel: false,
                      hint: "Enter SWP title name",
                      controller: titleController,
                    ),
                    const SizedBox(height: AppPadding.tight),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Requires Permit?",
                        style: AppTypography.body,
                      ),
                      value: requiresPermit,
                      onChanged: (val) {
                        setDialogState(() => requiresPermit = val);
                      },
                    ),
                  ],
                ),
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
                        label: "Add",
                        height: 44,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Process implementation if confirmed and fields are valid
      if (shouldSave == true &&
          categoryController.text.trim().isNotEmpty &&
          titleController.text.trim().isNotEmpty) {
        final String inputCategory = categoryController.text.trim();
        final String inputTitle = titleController.text.trim();

        if (mounted) setState(() => _isLoading = true);

        await supabase.from('swp_templates').insert({
          'category': inputCategory,
          'title': inputTitle,
          'requires_permit': requiresPermit,
        });

        if (mounted) await _fetchSwp();
      }
    } catch (e) {
      debugPrint("Error processing database query: $e");
    } finally {
      // Clean up controllers and ensure loading indicator is reset safely
      categoryController.dispose();
      titleController.dispose();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVisibility(
    List<int> idsToUpdate,
    String name,
    bool isHiding,
  ) async {
    final String actionStr = isHiding ? "Hide" : "Unhide";
    final String warningText = isHiding
        ? "Are you sure you want to hide $name? Technicians won't be able to make reports with this template anymore."
        : "Are you sure you want to unhide $name? Technicians will be able to use this template again.";

    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Text(
          "$actionStr $name?",
          style: AppTypography.Blackheading.copyWith(
            fontSize: 24,
            color: isHiding ? Colors.red : Colors.green,
          ),
        ),
        content: Text(
          warningText,
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
              actionStr,
              style: AppTypography.body.copyWith(
                color: isHiding ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await supabase
            .from('swp_templates')
            .update({'is_active': !isHiding}) // Flips the state
            .filter('id', 'in', idsToUpdate);

        _fetchSwp();
      } catch (e) {
        debugPrint("Error updating visibility: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to $actionStr $name. Error: $e")),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSwp(int id, String name) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Text(
          "Delete $name?",
          style: AppTypography.Blackheading.copyWith(
            fontSize: 24,
            color: Colors.red,
          ),
        ),
        content: Text(
          "Are you sure you want to permanently delete this SWP? This action cannot be undone.",
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
      setState(() => _isLoading = true);
      try {
        await supabase.from('swp_templates').delete().eq('id', id);

        if (mounted) await _fetchSwp();
      } on PostgrestException catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          // Error 23503 is standard PostgreSQL for Foreign Key Violation
          if (e.code == '23503') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Cannot delete $name because it is used in existing reports. Please hide it instead.",
                ),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Database error: ${e.message}")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);

          // Catch block for the manual check approach
          if (e.toString().contains('in_use')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Cannot delete $name because it is used in existing reports. Please hide it instead.",
                ),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to delete $name. Error: $e")),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(title: "Manage SWPs"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.page),
              child: Column(
                children: [
                  const SizedBox(height: AppPadding.medium),
                  // List of  SWPs
                  Expanded(
                    child: _swp.isEmpty
                        ? const Center(
                            child: Text(
                              "No SWPs found",
                              style: AppTypography.Blacksubheading,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _swp.length,
                            itemBuilder: (context, index) {
                              final group = _swp[index];
                              final String categoryName = group['category'];
                              final List<Map<String, dynamic>> activities =
                                  List<Map<String, dynamic>>.from(
                                    group['titles'],
                                  );
                              final List<int> categoryIds = activities
                                  .map((activity) => activity["id"] as int)
                                  .toList();
                              final bool isAllHidden = activities.every(
                                (activity) => activity['is_active'] == false,
                              );
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall,
                                  ),
                                ),
                                color: AppColors.primaryTint,
                                elevation: 0,
                                margin: const EdgeInsets.only(
                                  bottom: AppPadding.medium,
                                ),
                                child: ExpansionTile(
                                  key: PageStorageKey<String>(categoryName),
                                  initiallyExpanded: _expandedCategories
                                      .contains(categoryName),
                                  onExpansionChanged: (bool expanded) {
                                    setState(() {
                                      if (expanded) {
                                        _expandedCategories.add(categoryName);
                                      } else {
                                        _expandedCategories.remove(
                                          categoryName,
                                        );
                                      }
                                    });
                                  },
                                  collapsedShape: const Border(),
                                  shape: const Border(),
                                  title: Text(
                                    categoryName,
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${activities.length} activities",
                                    style: AppTypography.faintbody,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // EDIT BUTTON
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_note,
                                          color: AppColors.textMain,
                                        ),
                                        onPressed: () => _editSwpDialog(
                                          idsToEdit: categoryIds,
                                          name: categoryName,
                                          isCategory: true,
                                          requires_permit: null,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isAllHidden
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: isAllHidden
                                              ? Colors.grey
                                              : AppColors.primaryBlue,
                                        ),
                                        onPressed: () => _toggleVisibility(
                                          categoryIds,
                                          categoryName,
                                          !isAllHidden,
                                        ),
                                      ),

                                      const SizedBox(width: AppPadding.tight),
                                      AnimatedRotation(
                                        turns:
                                            _expandedCategories.contains(
                                              categoryName,
                                            )
                                            ? 0.5
                                            : 0, // Rotates 180 degrees when open
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Icon(
                                          Icons.expand_more,
                                          color:
                                              _expandedCategories.contains(
                                                categoryName,
                                              )
                                              ? AppColors.primaryBlue
                                              : null, // Match your default arrow color
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    // List all activities inside this category
                                    ...activities.map((activity) {
                                      final int id = activity['id'];
                                      final bool isActive =
                                          activity['is_active'];
                                      final bool isRequiredPermit =
                                          activity['requires_permit'];
                                      return ListTile(
                                        tileColor: AppColors.primaryTint,
                                        title: Text(
                                          activity['name'],
                                          style: AppTypography.body,
                                        ),
                                        subtitle: Text(
                                          "Permit Required: ${activity['requires_permit'] ? 'YES' : 'NO'}",
                                          style: TextStyle(
                                            color: activity['requires_permit']
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // EDIT BUTTON
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_note,
                                                color: AppColors.textMain,
                                              ),
                                              onPressed: () => _editSwpDialog(
                                                idsToEdit: [id],
                                                name: activity['name'],
                                                isCategory: false,
                                                requires_permit:
                                                    isRequiredPermit,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                isActive
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                                color: isActive
                                                    ? AppColors.primaryBlue
                                                    : Colors.grey,
                                              ),
                                              onPressed: () =>
                                                  _toggleVisibility(
                                                    [id],
                                                    activity['name'],
                                                    isActive,
                                                  ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_forever,
                                                color: Colors.red,
                                              ),
                                              onPressed: () => _deleteSwp(
                                                id,
                                                activity['name'],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const Divider(
                    height: AppPadding.large,
                    thickness: 1,
                    color: Color(0xFFE0E0E0),
                  ),

                  // Add Swp Button
                  _AddSwpButton(onTap: () => _showAddSwpDialog()),
                  const SizedBox(height: AppPadding.medium),
                ],
              ),
            ),
    );
  }
}

// Custom Add Department Button Widget
class _AddSwpButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddSwpButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MenuButton(
      label: "Add Safety Work Procedure",
      icon: Icons.people,

      onTap: onTap,
      // Custom styling for the button
    );
  }
}
