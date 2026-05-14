import 'package:flutter/material.dart';

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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
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
            const SizedBox(width: 12),
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
        SizedBox(height: _above3m == false ? 20 : 0),
        if (_above3m == true) ...[
          const SizedBox(height: 12),
          Text(
            "Enter Permit To Work Number (Required):",
            style: TextStyle(
              color: Color.fromARGB(255, 64, 64, 64),
              fontSize: widget.isMobile ? 13 : 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ptwCtrl,
            decoration: InputDecoration(
              hintText: 'Enter PTW number',
              hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
              filled: true,
              fillColor: const Color.fromARGB(22, 37, 100, 235),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),

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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
