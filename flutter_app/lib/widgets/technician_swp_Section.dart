import 'package:flutter/material.dart';
import 'package:kkhazardscan/widgets/swp_checklist.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/WAH_Permit.dart';
import '../widgets/image_upload.dart';
import '../Design/style_constant.dart';
import '../widgets/App_Textfield.dart';

class TechnicianSwpSection extends StatefulWidget {
  final int templateId;
  final String categoryName;

  final String initialPtw;
  final bool initialAbove3m;
  final List<String> initialCheckedItems;
  final dynamic initialImage;
  final String initialDetails;
  final Function(String details) onDetailsChanged;

  final Function(bool isAbove3m, String ptw) onPtwChanged;
  final Function(List<String> checkedItems) onChecklistChanged;
  final Function(dynamic file) onImageChanged;
  final Function(bool isCleared) onAllChecked;

  const TechnicianSwpSection({
    super.key,
    required this.templateId,
    required this.categoryName,
    required this.onPtwChanged,
    required this.initialPtw,
    required this.initialCheckedItems,
    required this.initialImage,
    required this.onChecklistChanged,
    required this.onImageChanged,
    required this.initialAbove3m,
    required this.initialDetails,
    required this.onDetailsChanged,
    required this.onAllChecked,
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
  late final TextEditingController _detailsCtrl;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _detailsCtrl = TextEditingController(text: widget.initialDetails);

    if (widget.categoryName.toLowerCase().contains("work at height")) {
      isPtwCleared = !widget.initialAbove3m || widget.initialPtw.isNotEmpty;
    } else {
      isPtwCleared = true;
    }
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 420;
          return Column(
            children: [
              if (widget.categoryName.toLowerCase().contains("work at height"))
                WAHPermitWidget(
                  isMobile: true,
                  initialPtw: widget.initialPtw,
                  initialAbove3m: widget.initialAbove3m,
                  onValidityChanged: (isAbove3m, ptwNum) {
                    setState(() {
                      isPtwCleared = !isAbove3m || ptwNum.isNotEmpty;
                    });
                    widget.onPtwChanged(isAbove3m, ptwNum);
                  },
                ),
              SWPChecklistWidget(
                isMobile: isMobile,
                items: items,
                initialCheckedItems: widget.initialCheckedItems,
                onChecklistChanged: (updatedCheckedList) {
                  widget.onChecklistChanged(updatedCheckedList);
                },
                onAllChecked: (status) {
                  setState(() => isSafetyCleared = status);
                  widget.onAllChecked(status);
                },
              ),
              AppImageUpload(
                label: "Site Photos",
                onImageSelected: (file) {
                  widget.onImageChanged(file);
                },
              ),
              const SizedBox(height: AppPadding.medium),
              AppTextfield(
                label: "Details",
                hint: "Enter details here / Take photo to output AI details",
                controller: _detailsCtrl,
                Maxlines: 3,
                onChanged: (value) {
                  widget.onDetailsChanged(value.trim());
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
