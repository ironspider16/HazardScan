import 'package:flutter/material.dart';
import 'package:kkhazardscan/widgets/swp_checklist.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/WAH_Permit.dart';
import '../Design/style_constant.dart';

class TechnicianSwpSection extends StatefulWidget {
  final int templateId;
  final String categoryName;

  final String initialPtw;
  final bool initialAbove3m;
  final List<String> initialCheckedItems;

  final Function(bool isAbove3m, String ptw) onPtwChanged;
  final Function(List<String> checkedItems) onChecklistChanged;
  final Function(bool isCleared) onAllChecked;

  const TechnicianSwpSection({
    super.key,
    required this.templateId,
    required this.categoryName,
    required this.onPtwChanged,
    required this.initialPtw,
    required this.initialCheckedItems,
    required this.onChecklistChanged,
    required this.initialAbove3m,
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
  bool _hasLoadedData = false;

  bool get isWAH =>
      widget.categoryName.toLowerCase().contains("work at height");

  @override
  void initState() {
    super.initState();
    _loadItems();

    if (widget.categoryName.toLowerCase().contains("work at height")) {
      isPtwCleared = !widget.initialAbove3m || widget.initialPtw.isNotEmpty;
    } else {
      isPtwCleared = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensures data is only fetched once when the context becomes available
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    try {
      final response = await supabase
          .from('swp_items')
          .select('description')
          .eq('template_id', widget.templateId);

      if (mounted) {
        setState(() {
          items = List<String>.from(response.map((x) => x['description']));
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
              if (isWAH)
                WAHPermitWidget(
                  isMobile: true,
                  initialPtw: widget.initialPtw,
                  initialAbove3m: widget.initialAbove3m,
                  onValidityChanged: (isAbove3m, ptwNum) {
                    setState(() {
                      isPtwCleared = !isAbove3m || ptwNum.trim().isNotEmpty;
                    });
                    widget.onPtwChanged(isAbove3m, ptwNum.trim());
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
            ],
          );
        },
      ),
    );
  }
}
