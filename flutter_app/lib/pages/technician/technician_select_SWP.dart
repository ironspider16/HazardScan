import 'package:kkhazardscan/pages/technician_swp_page.dart';
import '../../widgets/swp_category_card.dart';
import '../../widgets/Menu_button.dart';
import '../../Design/style_constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class TechnicianSelectSwp extends StatefulWidget {
  final int templateId;
  final String categoryName;

  const TechnicianSelectSwp({
    super.key,
    required this.templateId,
    required this.categoryName,
  });

  @override
  State<TechnicianSelectSwp> createState() => _TechnicianSelectSwpState();
}

class _TechnicianSelectSwpState extends State<TechnicianSelectSwp> {
  final supabase = Supabase.instance.client;
  bool isLoadingSWPs = true;
  List<String> swpTemplates = [];
  final Set<String> selectedswpTemplates = {};

  @override
  void initState() {
    super.initState();
    loadSWPTemplates();
  }

  Future<void> loadSWPTemplates() async {
    try {
      final response = await supabase
          .from('swp_templates')
          .select('id, category')
          .order('category');

      final allSWPs = response.map((item) => item['category'] as String);

      setState(() {
        swpTemplates = allSWPs.toSet().toList();
        isLoadingSWPs = false;
      });

      debugPrint(swpTemplates.join(","));
    } catch (e) {
      setState(() => isLoadingSWPs = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading activities : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingSWPs) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double fieldWidth = (MediaQuery.of(context).size.width * 0.85).clamp(
      300.0,
      450.0,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Work Activity",
          style: AppTypography.Blacksubheading,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppPadding.page),
                child: Column(
                  children: [
                    Center(
                      child: SizedBox(
                        width: fieldWidth,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: swpTemplates.length,
                          itemBuilder: (context, index) {
                            final category = swpTemplates[index];
                            final isSelected = selectedswpTemplates.contains(
                              category,
                            );

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppPadding.medium,
                              ),
                              child: SizedBox(
                                height: AppPadding.Largest * 2.5,
                                child: SwpCategoryCard(
                                  isSelected: isSelected,
                                  CategoryName: category,
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedswpTemplates.remove(category);
                                      } else {
                                        selectedswpTemplates.add(category);
                                      }
                                    });
                                  },
                                ), //
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppPadding.page),
              child: Column(
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: Divider(
                      height: AppPadding.large,
                      thickness: 1,
                      color: AppColors.borderGrey,
                    ),
                  ),
                  const SizedBox(height: AppPadding.tight),
                  SizedBox(
                    width: fieldWidth,
                    child: MenuButton(
                      label: selectedswpTemplates.isNotEmpty
                          ? "Continue"
                          : "Select to continue",
                      isDisabled: selectedswpTemplates.isEmpty,
                      onTap: _handleContinue,
                      isPrimary: true,
                      icon: Icons.arrow_right_alt_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleContinue() {
    if (selectedswpTemplates.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TechnicianSWPPage(
          selectedCategories: selectedswpTemplates.toList(),
        ),
      ),
    );
  }
}
