import 'package:flutter/material.dart';
import 'package:kkhazardscan/pages/admin/manage_checklist_items_page.dart';
import 'package:kkhazardscan/supabase_client.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

class SelectCategoryManageCheckListItems extends StatefulWidget {
  const SelectCategoryManageCheckListItems({super.key});

  @override
  State<SelectCategoryManageCheckListItems> createState() =>
      _SelectCategoryManageCheckListItemsState();
}

class _SelectCategoryManageCheckListItemsState
    extends State<SelectCategoryManageCheckListItems> {
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // 1. Get data from Supabase
  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('swp_templates')
          .select()
          .order('category', ascending: true);
      setState(() => _templates = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load. Please try again.")),
        );
      }
      debugPrint("Error fetching Categories: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(title: "Select Category"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.page),
              child: Column(
                children: [
                  const SizedBox(height: AppPadding.medium),
                  // List of Locations
                  Expanded(
                    child: ListView.separated(
                      itemCount: _templates.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppPadding.tight),
                      itemBuilder: (context, index) {
                        final category = _templates[index];
                        final id = category['id'] as int? ?? 1;
                        return _SwpRow(
                          category: category['category'] ?? 'No Category',
                          title: category['title'] ?? 'No Title',
                          id: id,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ManageChecklistItemsPage(categoryId: id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Custom Row Widget based on Figma
class _SwpRow extends StatelessWidget {
  final String category;
  final String title;
  final int id;
  final VoidCallback onTap;

  const _SwpRow({
    required this.category,
    required this.title,
    required this.id,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
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
            Expanded(
              child: Text('$category - $title', style: AppTypography.body),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
