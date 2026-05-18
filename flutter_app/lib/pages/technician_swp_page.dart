import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kkhazardscan/config/app_users.dart';
import 'package:kkhazardscan/pages/main_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../design/style_constant.dart';
import '../widgets/technician_swp_Section.dart';
import '../widgets/Menu_button.dart'; // Make sure MenuButton is imported

class TechnicianSWPPage extends StatefulWidget {
  final List<String> selectedCategories;
  final Map<String, dynamic>?
  task; // Fixed: Restored task property to prevent widget.task errors

  const TechnicianSWPPage({
    super.key,
    required this.selectedCategories,
    this.task, // Optional for flexibility
  });

  @override
  State<TechnicianSWPPage> createState() => _TechnicianSWPPageState();
}

class _TechnicianSWPPageState extends State<TechnicianSWPPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> allTemplates = [];
  Map<String, int?> selectedSubCategories = {};
  bool isLoading = true;

  final Map<int, String> _savedPtwNumbers = {};
  final Map<int, bool> _savedAbove3m = {};
  final Map<int, List<String>> _savedChecklists = {};
  final Map<int, dynamic> _savedImages = {};
  final Map<int, String> _savedDetails = {};

  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
  }

  Future<void> _fetchSubCategories() async {
    try {
      setState(() => isLoading = true);

      final response = await supabase
          .from('swp_templates')
          .select('id, category, title')
          .order('title');

      final templateList = List<Map<String, dynamic>>.from(response);

      setState(() {
        allTemplates = templateList
            .where((t) => widget.selectedCategories.contains(t['category']))
            .toList();

        for (String category in widget.selectedCategories) {
          final matchedList = allTemplates
              .where((t) => t['category'] == category)
              .toList();
          if (matchedList.isNotEmpty) {
            selectedSubCategories[category] = matchedList.first['id'] as int;
          } else {
            selectedSubCategories[category] = null;
          }
          debugPrint("matched list: " + matchedList.toString());
        }
        isLoading = false;
        debugPrint("template list" + templateList.toString());
        debugPrint("all templates" + allTemplates.toString());
        debugPrint(
          "selected sub categories; " + selectedSubCategories.toString(),
        );
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error fetching sub-categories : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> submitReport() async {
    try {
      setState(() => isLoading = true);

      final activeSubCategoryIds = selectedSubCategories.values
          .where((id) => id != null)
          .cast<int>()
          .toList();

      if (activeSubCategoryIds.isEmpty) {
        throw Exception(
          "Please select at least one activity type before submitting.",
        );
      }

      List<Map<String, dynamic>> recordsToInsert = [];

      for (int templateId in activeSubCategoryIds) {
        String ptwNumber = _savedPtwNumbers[templateId] ?? "";
        String detailsText = _savedDetails[templateId] ?? "";

        recordsToInsert.add({
          'swp_template_id': templateId,

          'wah_permit_numbers': ptwNumber.isNotEmpty ? ptwNumber : null,

          'Details': detailsText.isNotEmpty ? detailsText : null,
        });
      }

      await supabase.from('safety_reports').insert(recordsToInsert);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All safety checks successfully submitted!"),
            backgroundColor: Colors.green,
          ),
        );

        final anonymousTechnician = AppUser(
          id: 0,
          email: "technician@example.com",
          password: '',
          role: UserRole.user,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MainMenu(user: anonymousTechnician),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Submission failed: ${e.toString().replaceAll('Exception: ', '')}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double fieldWidth = (MediaQuery.of(context).size.width * 0.85).clamp(
      300.0,
      450.0,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          widget.task != null
              ? "Task SWPs: ${widget.task!['workorder_id']}"
              : "Activity Checklists",
          style: AppTypography.Bluesubheading,
        ),
        foregroundColor: AppColors.textMain,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppPadding.page),
                    itemCount: widget.selectedCategories.length,
                    itemBuilder: (context, index) {
                      final category = widget.selectedCategories[index];

                      final categoryTemplates = allTemplates
                          .where((t) => t['category'] == category)
                          .toList();

                      final currentSelectedId = selectedSubCategories[category];

                      return Card(
                        color: AppColors.primaryTint,
                        margin: const EdgeInsets.only(
                          bottom: AppPadding.medium,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          backgroundColor: AppColors.primaryTint.withAlpha(10),
                          title: Text(category, style: AppTypography.body),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppPadding.medium,
                                vertical: AppPadding.tight,
                              ),
                              child: DropdownButtonFormField<int>(
                                initialValue: currentSelectedId,
                                decoration: InputDecoration(
                                  labelText: "Select Specific Activity Type",
                                  filled: true,
                                ),
                                items: categoryTemplates.map((t) {
                                  return DropdownMenuItem<int>(
                                    value: t['id'] as int,
                                    child: Text(
                                      t['title']?.toString().trim() ??
                                          'Untitled',
                                      style: AppTypography.body,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedSubCategories[category] = newValue;

                                    if (newValue != null) {
                                      _savedPtwNumbers.putIfAbsent(
                                        newValue,
                                        () => "",
                                      );
                                      _savedAbove3m.putIfAbsent(
                                        newValue,
                                        () => false,
                                      );
                                      _savedChecklists.putIfAbsent(
                                        newValue,
                                        () => [],
                                      );
                                      _savedDetails.putIfAbsent(
                                        newValue,
                                        () => "",
                                      );
                                    }
                                  });
                                },
                              ),
                            ),

                            if (currentSelectedId != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppPadding.tight,
                                ),
                                child: TechnicianSwpSection(
                                  key: ValueKey(currentSelectedId),
                                  templateId: currentSelectedId,
                                  categoryName: category,
                                  initialPtw:
                                      _savedPtwNumbers[currentSelectedId] ?? "",
                                  initialAbove3m:
                                      _savedAbove3m[currentSelectedId] ?? false,
                                  initialCheckedItems:
                                      _savedChecklists[currentSelectedId] ?? [],
                                  initialImage: _savedImages[currentSelectedId],
                                  initialDetails:
                                      _savedDetails[currentSelectedId] ?? "",
                                  onPtwChanged: (isAbove3m, ptw) {
                                    _savedPtwNumbers[currentSelectedId] = ptw;
                                    _savedAbove3m[currentSelectedId] =
                                        isAbove3m;
                                  },
                                  onChecklistChanged: (checkedList) {
                                    _savedChecklists[currentSelectedId] =
                                        checkedList;
                                  },
                                  onImageChanged: (file) {
                                    setState(() {
                                      _savedImages[currentSelectedId] = file;
                                    });
                                  },
                                  onDetailsChanged: (textValue) {
                                    _savedDetails[currentSelectedId] =
                                        textValue;
                                  },
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.all(AppPadding.medium),
                                child: Text(
                                  "No specific activities configured for this field.",
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(AppPadding.page),
                  child: Column(
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: const Divider(
                          height: AppPadding.large,
                          thickness: 1,
                          color: AppColors.borderGrey,
                        ),
                      ),
                      const SizedBox(height: AppPadding.tight),
                      SizedBox(
                        width: fieldWidth,
                        child: MenuButton(
                          label: "Submit Safety Report",
                          onTap: submitReport,
                          isPrimary: true,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
