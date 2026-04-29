import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/swp.dart';

class SwpRecordService {
  SwpRecordService._();
  static final SwpRecordService instance = SwpRecordService._();

  static const _fileName = 'swp_records.txt';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<String>> loadRawRecords() async {
    final f = await _file();
    if (!await f.exists()) return [];
    final txt = await f.readAsString();
    if (txt.trim().isEmpty) return [];
    return txt
        .split('\n---\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> appendRecord(SwpRecord r) async {
    final f = await _file();
    final entry = _serialize(r);

    if (!await f.exists()) {
      await f.writeAsString(entry);
    } else {
      final old = await f.readAsString();
      final next = old.trim().isEmpty ? entry : '$old\n---\n$entry';
      await f.writeAsString(next);
    }
  }

  String _serialize(SwpRecord r) {
    // Simple text format (easy to view / demo)
    final buf = StringBuffer();
    buf.writeln('TITLE:${r.templateTitle}');
    buf.writeln('CATEGORY:${r.category.name}');
    buf.writeln('DATE:${r.createdAt.toIso8601String()}');

    // ✅ Acknowledgement details (from Ack page)
    buf.writeln('NAME:${r.name}');
    buf.writeln('DESIGNATION:${r.designation}');
    buf.writeln('DEPARTMENT:${r.department}');

    // ✅ WAH PTW info
    if (r.category == SwpCategory.wah) {
      buf.writeln('WAH_ABOVE_3M:${r.workingAbove3m == true ? 'YES' : 'NO'}');
      buf.writeln('PTW_NUMBER:${r.ptwNumber ?? ''}');
    }

    // ✅ Checklist / attachments / notes
    buf.writeln('CHECKS:${r.checks.map((e) => e ? '1' : '0').join("")}');
    buf.writeln('ATTACHMENTS:${r.attachments.join("|")}');
    buf.writeln('NOTES:${r.notes.replaceAll("\n", "\\n")}');

    return buf.toString().trim();
  }
}
