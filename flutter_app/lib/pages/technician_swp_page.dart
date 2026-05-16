import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../design/style_constant.dart';
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
  Map<int, String> swpPermitNumbers = {};

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

  Future<void> submitReport() async {
    List<String> finalPtwList = swpPermitNumbers.values.where((ptw) => ptw.isNotEmpty)
        .toSet()
        .toList();

    await supabase.from('safety_reports').insert({
      'task_id': widget.task['id'],
      'wah_permit_numbers' : finalPtwList,
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          "Task SWPs: ${widget.task['workorder_id']}",
          style: AppTypography.Bluesubheading,
        ),
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(AppPadding.page),
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
                  color: const Color.fromARGB(255, 239, 244, 255),
                  // color: const Color.fromARGB(255, 226, 235, 255),
                  margin: const EdgeInsets.only(bottom: AppPadding.tight),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    backgroundColor: const Color.fromARGB(255, 239, 244, 255),
                    title: Text(
                      title,
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(category, style: AppTypography.body),
                    children: [
                      if (templateId != 0)
                        TechnicianSwpSection(
                          templateId: templateId,
                          categoryName: category,
                          onPtwChanged: (ptw) {
                            swpPermitNumbers[templateId] = ptw;
                          },

                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(AppPadding.medium),
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
