import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:kkhazardscan/supabase_client.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:markdown_editor_live/markdown_editor_live.dart';

class MonthlyReportDetailScreen extends StatefulWidget {
  final String content;
  final String date;
  final int id;

  const MonthlyReportDetailScreen({
    super.key,
    required this.content,
    required this.date,
    required this.id,
  });

  @override
  State<MonthlyReportDetailScreen> createState() =>
      _MonthlyReportDetailScreenState();
}

class _MonthlyReportDetailScreenState extends State<MonthlyReportDetailScreen> {
  late String _currentContent;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentContent = widget.content;
  }

  Future<void> _saveReport() async {
    if (widget.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Missing Report ID.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await supabase
          .from('monthly_reports')
          .update({'report_content': _currentContent})
          .eq('id', widget.id);

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Monthly report updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save updates: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final markdownStyle = MarkdownStyleSheet(
      h1: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors
            .primaryBlue, // Matches app header typography color anchors
        height: 1.4,
      ),
      h2: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryBlueLight,
        height: 1.5,
      ),
      h3: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
      p: const TextStyle(
        fontSize: 14,
        height: 1.6, // Adds breathing room between sentences
        color: AppColors.textMain,
      ),
      listBullet: const TextStyle(
        fontSize: 14,
        color: AppColors
            .primaryBlue, // Colors bullet anchors to stand out uniformly
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 1.0, color: Colors.grey.shade300),
        ),
      ),
      blockSpacing: AppPadding
          .medium, // Control padding intervals between structural text nodes
      listIndent: AppPadding.extraLarge,
    );
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(
        title: _isEditing ? "Editing Report" : "Monthly Overview",
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(_isEditing ? Icons.save_rounded : Icons.edit_outlined),
              color: AppColors.primaryBlue,
              tooltip: _isEditing ? "Save Changes" : "Edit Report",
              onPressed: () {
                if (_isEditing) {
                  _saveReport();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
          if (_isEditing && !_isSaving)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey),
              tooltip: "Cancel",
              onPressed: () {
                setState(() {
                  _currentContent = widget.content;
                  _isEditing = false;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppPadding.page,
              vertical: AppPadding.tight,
            ),
            padding: const EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withValues(alpha: 0.4),
            ),

            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: AppPadding.tight,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.blue.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: AppPadding.tight),
                      Text(
                        "Reporting Period:",
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.date,
                    style: AppTypography.body.copyWith(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isEditing
                ? Padding(
                    padding: const EdgeInsets.all(AppPadding.page),
                    child: Container(
                      padding: const EdgeInsets.all(AppPadding.medium),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMedium,
                        ),
                        border: Border.all(
                          color: AppColors.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      child: MarkdownEditor(
                        initialValue: _currentContent,
                        onChanged: (text) => _currentContent = text,
                        style: AppTypography.body.copyWith(height: 1.6),
                        useSoftTabs: true,
                        tabWidth: 2,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type report changes here...',
                        ),
                      ),
                    ),
                  )
                : Markdown(
                    data: _currentContent,
                    styleSheet: markdownStyle,
                    padding: const EdgeInsets.all(AppPadding.page),
                  ),
          ),
        ],
      ),
    );
  }
}
