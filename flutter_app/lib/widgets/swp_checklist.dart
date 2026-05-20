import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

class SWPChecklistWidget extends StatefulWidget {
  final List<String> items;
  final List<String> initialCheckedItems;
  final Function(List<String> updatedCheckedList) onChecklistChanged;
  final Function(bool) onAllChecked;
  final bool isMobile;

  const SWPChecklistWidget({
    super.key,
    required this.items,
    required this.onAllChecked,
    required this.isMobile,
    required this.initialCheckedItems,
    required this.onChecklistChanged,
  });

  @override
  State<SWPChecklistWidget> createState() => _SWPChecklistWidgetState();
}

class _SWPChecklistWidgetState extends State<SWPChecklistWidget> {
  late Map<String, bool> _checklistState;

  @override
  void initState() {
    super.initState();
    _checklistState = {
      for (var item in widget.items)
        item: widget.initialCheckedItems.contains(item),
    };

    _notifyParentOfCompletion(safely: true);
  }

  @override
  void didUpdateWidget(covariant SWPChecklistWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.initialCheckedItems != widget.initialCheckedItems) {
      setState(() {
        _checklistState = {
          for (var item in widget.items)
            item: widget.initialCheckedItems.contains(item),
        };
      });
      _notifyParentOfCompletion(safely: true);
    }
  }

  void _updateCheck(String item, bool? value) {
    setState(() {
      _checklistState[item] = value ?? false;
    });

    List<String> currentlyChecked = _checklistState.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    widget.onChecklistChanged(currentlyChecked);
    _notifyParentOfCompletion(safely: false);
  }

  void _notifyParentOfCompletion({required bool safely}) {
    if (widget.items.isEmpty) return;
    bool allDone = _checklistState.values.every((checked) => checked);

    if (safely) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAllChecked(allDone);
      });
    } else {
      widget.onAllChecked(allDone);
    }
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
            title: Text(item, style: AppTypography.body.copyWith(fontSize: widget.isMobile? 11 : null)),
            value: _checklistState[item] ?? false,
            onChanged: (value) => _updateCheck(item, value),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primaryBlue,
          );
        }),
      ],
    );
  }
}
