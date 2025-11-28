import 'package:flutter/material.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Floating Camera Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 6,
        onPressed: () {},
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // HEADER
              const Text(
                "Main Menu",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Menu Buttons (centered)
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        // REPORTS BUTTON
                        _MenuButton(
                          icon: Icons.description_outlined,
                          label: "Reports",
                          color: const Color(0xFF2563EB),
                          onTap: () {},
                        ),
                        const SizedBox(height: 20),

                        // DASHBOARD BUTTON
                        _MenuButton(
                          icon: Icons.dashboard_outlined,
                          label: "Dashboard",
                          color: const Color(0xFF1F2937), // gray-900
                          onTap: () {},
                        ),
                        const SizedBox(height: 20),

                        // SETTINGS BUTTON
                        _MenuButton(
                          icon: Icons.settings_outlined,
                          label: "Settings",
                          color: const Color(0xFF1F2937),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Reusable Menu Button
// ---------------------------------------------------------------
class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),

      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color == const Color(0xFF2563EB)
                ? const Color(0xFF2563EB)
                : const Color(0xFF374151),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
      ),
    );
  }
}
