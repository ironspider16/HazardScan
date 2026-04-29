import 'package:flutter/material.dart';
import '../config/app_users.dart';
import '../models/swp.dart';
import '../data/swp_templates.dart';
import 'main_menu.dart';
import 'swp_checklist_page.dart';

class WorkActivityPage extends StatefulWidget {
  final AppUser user;

  const WorkActivityPage({super.key, required this.user});

  @override
  State<WorkActivityPage> createState() => _WorkActivityPageState();
}

class _WorkActivityPageState extends State<WorkActivityPage> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.role == UserRole.admin;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        automaticallyImplyLeading: false, // no back button after login
        title: const Text(
          'Select Work Activity',
          style: TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Choose your work activity:",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),

            _tile("Work at Height (WAH)"),
            const SizedBox(height: 12),
            _tile("Chemical Handling (LN2)"),
            const SizedBox(height: 12),
            _tile("Confined Space"),
            const SizedBox(height: 12),
            _tile("General Safety / Other"),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selected == null ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isAdmin ? "Continue" : "Continue",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label) {
    final selected = _selected == label;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selected = label),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB)
              : const Color.fromARGB(255, 157, 157, 157),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ FLOW LOGIC ------------------

  Future<void> _continue() async {
    final cat = _mapSelectionToCategory(_selected);

    // If "General Safety / Other", skip SWP and go main menu
    if (cat == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainMenu(user: widget.user)),
      );
      return;
    }

    final templates = templatesByCategory(cat);

    // If multiple templates (WAH/LN2), user must pick which SWP
    if (templates.length > 1) {
      final chosen = await Navigator.push<SwpTemplate?>(
        context,
        MaterialPageRoute(
          builder: (_) => _ProcedurePickPage(
            title: _selected ?? "Select Procedure",
            templates: templates,
          ),
        ),
      );

      if (chosen == null) return; // user backed out

      await _openChecklist(chosen);
      return;
    }

    // If only 1 template, go straight to checklist
    if (templates.isNotEmpty) {
      await _openChecklist(templates.first);
    }
  }

  SwpCategory? _mapSelectionToCategory(String? s) {
    switch (s) {
      case "Work at Height (WAH)":
        return SwpCategory.wah;
      case "Chemical Handling (LN2)":
        return SwpCategory.ln2;
      case "Confined Space":
        return SwpCategory.confined;
      default:
        return null; // General Safety / Other
    }
  }

  Future<void> _openChecklist(SwpTemplate template) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SwpChecklistPage(template: template)),
    );

    // After SWP submit -> go main menu
    if (submitted == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainMenu(user: widget.user)),
      );
    }
  }
}

// ------------------ PROCEDURE PICKER PAGE after Select Work Activity page ------------------

class _ProcedurePickPage extends StatelessWidget {
  final String title;
  final List<SwpTemplate> templates;

  const _ProcedurePickPage({required this.title, required this.templates});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final t = templates[i];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pop(context, t),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 157, 157, 157),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
