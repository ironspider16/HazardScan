import 'package:flutter/material.dart';
import 'package:kkhazardscan/widgets/swp_checklist.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/WAH_Permit.dart';
import '../widgets/image_upload.dart';
import '../Design/style_constant.dart';

class TechnicianSwpSection extends StatefulWidget {
  final int templateId;
  final String categoryName;

  const TechnicianSwpSection({
    super.key,
    required this.templateId,
    required this.categoryName,
  });

  @override
  State<TechnicianSwpSection> createState() => _TechnicianSwpSectionState();
}

class _TechnicianSwpSectionState extends State<TechnicianSwpSection> {
  final supabase = Supabase.instance.client;
  List<String> items = [];
  bool isSafetyCleared = false;
  bool isPtwCleared = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
    isPtwCleared = !widget.categoryName.toLowerCase().contains(
      "work at height",
    );
  }

  Future<void> _loadItems() async {
    final response = await supabase
        .from('swp_items')
        .select('description')
        .eq('template_id', widget.templateId);

    setState(() {
      items = List<String>.from(response.map((x) => x['description']));
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppPadding.page),
        child: LinearProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        children: [
          if (widget.categoryName.toLowerCase().contains("work at height"))
            WAHPermitWidget(
              isMobile: true,
              onValidityChanged: (isAbove3m, ptwNum) {
                setState(() {
                  isPtwCleared = !isAbove3m || ptwNum.isNotEmpty;
                });
              },
            ),
          SWPChecklistWidget(
            isMobile: true,
            items: items,
            onAllChecked: (status) => setState(() => isSafetyCleared = status),
          ),
          AppImageUpload(
            label: "Site Photos",
            onImageSelected: (file) {
              // Handle image logic here
            },
          ),
        ],
      ),
    );
  }
}
