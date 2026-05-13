import 'package:flutter/material.dart';
import 'package:kkhazardscan/config/app_users.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/Menu_button.dart';
import '../design/style_constant.dart';
import 'dart:io';
import '../widgets/technician_swp_Section.dart';

class TechnicianSWPPage extends StatefulWidget {
  final Map<String, dynamic> task;
  const TechnicianSWPPage({super.key, required this.task});

  @override
  State<TechnicianSWPPage> createState() => _TechnicianSWPPageState();
}

class _TechnicianSWPPageState extends State<TechnicianSWPPage> {
  final supabase = Supabase.instance.client;

  List<dynamic> swpTemplates = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTaskSWPs();
  }

  Future<void> _fetchTaskSWPs() async {
    setState(() => isLoading = true);
    setState(() => swpTemplates = widget.task['task_swp_assignments'] ?? []);
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text("Task SWPs: ${widget.task['workorder_id']}"),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: swpTemplates.length,
              itemBuilder: (context, index) {
                final templateData = swpTemplates[index]['swp_templates'];
                if (templateData == null) {
                  return const ListTile(title: Text("Template data missing"));
                }

                final int templateId =
                    templateData['id'] ?? 0; // Use 0 or -1 as a flag
                final String title = templateData['title'] ?? 'Untitled SWP';
                final String category = templateData['category'] ?? 'General';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    backgroundColor: Colors.grey.shade50,
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(category),
                    children: [
                      if (templateId != 0)
                        TechnicianSwpSection(
                          templateId: templateId,
                          categoryName: category,
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text("Error: Valid Template ID not Found"),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
