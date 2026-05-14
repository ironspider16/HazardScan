import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

class SWPChecklistWidget extends StatefulWidget {
  final List<String> items;
  final Function(bool) onAllChecked;
  final bool isMobile;

  const SWPChecklistWidget({
    super.key,
    required this.items,
    required this.onAllChecked,
    required this.isMobile,
  });

  @override
  State<SWPChecklistWidget> createState() => _SWPChecklistWidgetState();
}

class _SWPChecklistWidgetState extends State<SWPChecklistWidget> {
  late Map<String, bool> _checklistState;

  @override
  void initState() {
    //Initialize unchecked for list items
    super.initState();
    _initCheckList();
    _checklistState = {for (var item in widget.items) item: false};
  }

  @override
  void didUpdateWidget(covariant SWPChecklistWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _initCheckList();
    }
  }

  void _initCheckList() {
    _checklistState = {for (var item in widget.items) item: false};
  }

  void _updateCheck(String item, bool? value) {
    setState(() {
      _checklistState[item] = value ?? false;
    });

    bool allDone = _checklistState.values.every((checked) => checked);
    widget.onAllChecked(allDone);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Text("No items to display");
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Safety Compliance Checklist",
          style: AppTypography.Blacksubheading,
        ),
        const SizedBox(height: AppPadding.tight),
        ...widget.items.map((item) {
          return CheckboxListTile(
            title: Text(
              item,
              style: AppTypography.body.copyWith(fontSize: 14),
            ),
            value: _checklistState[item],
            onChanged: (value) => _updateCheck(item, value),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primaryBlue,
          );
        }),
      ],
    );
  }
}
