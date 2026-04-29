import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/reports_file_service.dart';

class ReportDetailPage extends StatefulWidget {
  final Report report;
  final int index;
  final bool isAdmin;

  const ReportDetailPage({
    super.key,
    required this.report,
    required this.index,
    required this.isAdmin,
  });

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool _isEditing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.report.title);
    _bodyController = TextEditingController(text: widget.report.body);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')} '
        '${_monthName(dt.month)} '
        '${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[m - 1];
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);

    final updated = Report(
      title: _titleController.text.trim().isEmpty
          ? widget.report.title
          : _titleController.text.trim(),
      createdAt: widget.report.createdAt,
      body: _bodyController.text.trim(),
    );

    await ReportsFileService.instance.updateReportAt(widget.index, updated);

    if (!mounted) return;

    setState(() {
      _isEditing = false;
      _saving = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Report updated')));

    // return "changed = true" to the list page
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          if (widget.isAdmin && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit report',
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _saving
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isEditing
                        ? TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 60, 60, 60),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              labelStyle: TextStyle(
                                color: Color.fromARGB(179, 31, 31, 31),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            report.title,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 45, 45, 45),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(report.createdAt),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 45, 45, 45),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color.fromARGB(255, 133, 133, 133)),
                    const SizedBox(height: 16),
                    _isEditing
                        ? TextField(
                            controller: _bodyController,
                            maxLines: null,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(
                                255,
                                119,
                                120,
                                120,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: 'Edit report body...',
                              hintStyle: const TextStyle(
                                color: Color.fromARGB(255, 45, 45, 45),
                              ),
                            ),
                          )
                        : Text(
                            report.body,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 45, 45, 45),
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                    const SizedBox(height: 20),
                    if (widget.isAdmin && _isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color.fromARGB(
                                  255,
                                  65,
                                  65,
                                  65,
                                ),
                                side: const BorderSide(
                                  color: Color.fromARGB(97, 56, 56, 56),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _titleController.text = report.title;
                                  _bodyController.text = report.body;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _saveChanges,
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
