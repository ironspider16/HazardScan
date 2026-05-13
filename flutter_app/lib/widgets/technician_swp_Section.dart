import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kkhazardscan/widgets/swp_checklist.dart';
import '../Design/style_constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/WAH_Permit.dart';
import '../widgets/image_upload.dart';

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
    if (isLoading)
      return const Padding(
        padding: EdgeInsets.all(20),
        child: LinearProgressIndicator(),
      );

    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          const SizedBox(height: 10),
          AppImageUpload(
            label: "Site Photos",
            onImageSelected: (file) {
              // Handle image logic here
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (isSafetyCleared && isPtwCleared)
                ? () {
                    // Save only this specific SWP progress
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("SWP Progress Saved Locally"),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text("Save SWP Progress"),
          ),
        ],
      ),
    );
  }
}
