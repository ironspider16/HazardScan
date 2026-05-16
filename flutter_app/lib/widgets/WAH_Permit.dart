import 'package:flutter/material.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import '../Design/style_constant.dart';

class WAHPermitWidget extends StatefulWidget {
  final Function(bool isAbove3m, String ptwNumber) onValidityChanged;
  final bool isMobile;

  const WAHPermitWidget({
    super.key,
    required this.onValidityChanged,
    required this.isMobile,
  });

  @override
  State<WAHPermitWidget> createState() => _WAHPermitWidgetState();
}

class _WAHPermitWidgetState extends State<WAHPermitWidget> {
  bool? _above3m = false;
  final _ptwCtrl = TextEditingController();
  

  void _notifyParent() {
    widget.onValidityChanged(_above3m ?? false, _ptwCtrl.text.trim());
  }

  @override
  void dispose() {
    _ptwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Work at height above 3 metres?',
          style: AppTypography.Blacksubheading,
        ),
        const SizedBox(height: AppPadding.medium),
        Row(
          children: [
            Expanded(
              child: _pill(
                label: 'No',
                selected: _above3m == false,
                onTap: () {
                  setState(() => _above3m = false);
                  _notifyParent();
                },
              ),
            ),
            const SizedBox(width: AppPadding.tight),
            Expanded(
              child: _pill(
                label: 'Yes',
                selected: _above3m == true,
                onTap: () {
                  setState(() => _above3m = true);
                  _notifyParent();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: _above3m == false ? AppPadding.medium : 0),
        if (_above3m == true) ...[
          const SizedBox(height: AppPadding.medium),
          AppTextfield(
            label: "Enter Permit To Work Number (Required)", 
            hint: "Enter PTW number",
            controller: _ptwCtrl,
            onChanged: (value) => _notifyParent(),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: AppPadding.extraLarge,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : AppColors.borderGrey.withAlpha(95),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(color: AppColors.backgroundWhite),
        ),
      ),
    );
  }
}
