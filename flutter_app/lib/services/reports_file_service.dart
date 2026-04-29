import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/report.dart';

class ReportsFileService {
  ReportsFileService._();
  static final ReportsFileService instance = ReportsFileService._();

  static const String _fileName = 'reports.txt';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Seed content for testing – two example reports.
  static const String _seedContent = '''
Fall hazard near ICU
2025-12-12T10:30:00
A maintenance worker was observed using an unsecured ladder near the ICU entrance.
The ladder was leaning at an unsafe angle and was not locked in place.
Recommended actions:
- Remove the ladder from service immediately.
- Replace with a compliant ladder.
- Educate maintenance staff on ladder safety.

===

Scaffolding obstruction at ED entrance
2025-12-11T15:10:00
Temporary scaffolding was partially blocking the emergency department vehicle bay.
This created a potential delay for incoming emergency vehicles.
Recommended actions:
- Reposition scaffolding to maintain clear access.
- Add clear signage and barriers around the work zone.
- Review contractor compliance with site access policies.
''';

  /// Load and parse all reports.
  /// If file does not exist, create it with seed content.
  Future<List<Report>> loadReports() async {
    final file = await _getFile();

    if (!await file.exists()) {
      // First run – create example reports.txt
      await file.writeAsString(_seedContent.trim());
    }

    final txt = await file.readAsString();
    if (txt.trim().isEmpty) return [];

    // Each report is separated by "\n===\n"
    final blocks = txt.split('\n===\n');
    final List<Report> reports = [];

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 3) continue;

      final title = lines[0].trim();
      final dateRaw = lines[1].trim();
      final body = lines.sublist(2).join('\n').trim();

      DateTime dt;
      try {
        dt = DateTime.parse(dateRaw);
      } catch (_) {
        dt = DateTime.now();
      }

      reports.add(
        Report(
          title: title,
          createdAt: dt,
          body: body,
        ),
      );
    }

    // Newest first
    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  }

  /// Overwrite file with a new list of reports (for future use).
  Future<void> saveReports(List<Report> reports) async {
    final file = await _getFile();
    final buffer = StringBuffer();

    for (var i = 0; i < reports.length; i++) {
      final r = reports[i];
      buffer.writeln(r.title);
      buffer.writeln(r.createdAt.toIso8601String());
      buffer.writeln(r.body.trim());
      if (i != reports.length - 1) {
        buffer.writeln('\n===\n');
      }
    }

    await file.writeAsString(buffer.toString());
  }

  /// Later, when LLM generates a new report, you can call this.
  Future<void> appendReport(Report report) async {
    final existing = await loadReports();
    existing.add(report);
    await saveReports(existing);
  }

  Future<void> updateReportAt(int index, Report updated) async {
  final list = await loadReports();
  if (index < 0 || index >= list.length) return;
  list[index] = updated;
  await saveReports(list);
  }

}
