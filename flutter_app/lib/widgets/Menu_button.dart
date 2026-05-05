import 'package:flutter/material.dart';

class MenuButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon; // Added an optional icon field

  const MenuButton({super.key, required this.label, required this.onTap, this.icon});

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: double.infinity, // Set to fill available width
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color.fromARGB(255, 147, 147, 147),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 16,
                color: _pressed ? Colors.white : const Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.icon != null) ...[
              const SizedBox(width: 8),
              Icon(
                widget.icon,
                size: 20,
                color: _pressed ? Colors.white : const Color(0xFF333333),
              ),
            ],
          ],
        ),
      ),
    );
  }
}