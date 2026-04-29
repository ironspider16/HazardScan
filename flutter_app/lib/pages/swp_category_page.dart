import 'package:flutter/material.dart';
import '../models/swp.dart';
import '../data/swp_templates.dart';
import 'swp_checklist_page.dart';

class SwpCategoryPage extends StatelessWidget {
  const SwpCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Safe Work Procedures',
          style: TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _catTile(context, 'Work at Height (WAH)', SwpCategory.wah),
          const SizedBox(height: 12),
          _catTile(context, 'Chemical Handling — LN2', SwpCategory.ln2),
          const SizedBox(height: 12),
          _catTile(context, 'Confined Space Work', SwpCategory.confined),
        ],
      ),
    );
  }

  Widget _catTile(BuildContext context, String title, SwpCategory cat) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final templates = templatesByCategory(cat);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _TemplatePickPage(title: title, templates: templates),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.checklist, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _TemplatePickPage extends StatelessWidget {
  final String title;
  final List<SwpTemplate> templates;

  const _TemplatePickPage({required this.title, required this.templates});

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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SwpChecklistPage(template: t),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
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
