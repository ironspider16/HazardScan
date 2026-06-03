import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class LocalReportCompiler {
  static Future<Uint8List> generateWshReport({
    required String location,
    required String supervisor,
    required String employer,
    required Map<String, dynamic> initialAiData,
    required String manualNotes,
    Uint8List? imageBytes,
  }) async {
    final pdf = pw.Document();

    // Extract blocks
    final Map<String, dynamic> ladder = initialAiData['ladderHeight'] ?? {};
    final Map<String, dynamic> ppe = initialAiData['ppe'] ?? {};
    final Map<String, dynamic> buddy = initialAiData['buddySystem'] ?? {};
    final Map<String, dynamic> hazards = initialAiData['areaHazards'] ?? {};
    final String overallStatus = initialAiData['overallStatus'] ?? 'PENDING';

    String getField(Map<String, dynamic> block, String field) =>
        block[field]?.toString().trim() ?? 'Not Declared';

    final String currentDate = DateTime.now().toIso8601String().split('T')[0];
    final String currentTime =
        "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";

    // Decode image if present
    pw.MemoryImage? siteImage;
    if (imageBytes != null) {
      siteImage = pw.MemoryImage(imageBytes);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Header
          pw.Text(
            'WSH INSPECTION REPORT',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // Section 1
          _sectionHeader('1. Site and Personnel Details'),
          _field('Date & Time', '$currentDate at $currentTime SGT'),
          _field('Location', location.isEmpty ? 'Not Declared' : location),
          _field('Supervisor', supervisor.isEmpty ? 'Unassigned' : supervisor),
          _field('Employer', employer.isEmpty ? 'Not Declared' : employer),
          pw.SizedBox(height: 12),

          // Section 2
          _sectionHeader('2. Hazard Identification'),
          _field('Working at Heights', getField(ladder, 'description')),
          _field('PPE', getField(ppe, 'description')),
          _field('Area Hazards', getField(hazards, 'description')),
          _field('Manual Notes', manualNotes.isEmpty ? 'None' : manualNotes),
          pw.SizedBox(height: 12),

          // Section 3
          _sectionHeader('3. Risk Assessment'),
          _field('Overall Status', overallStatus),
          _field('Heights Compliance', getField(ladder, 'compliance')),
          _field('Heights Reasoning', getField(ladder, 'reasoning')),
          _field('PPE Compliance', getField(ppe, 'compliance')),
          _field('PPE Reasoning', getField(ppe, 'reasoning')),
          _field('Buddy System Compliance', getField(buddy, 'compliance')),
          _field('Buddy System Reasoning', getField(buddy, 'reasoning')),
          pw.SizedBox(height: 12),

          // Section 4
          _sectionHeader('4. Corrective Measures'),
          _field('Heights Advice', getField(ladder, 'advice')),
          _field('PPE Advice', getField(ppe, 'advice')),
          _field('Area Advice', getField(hazards, 'advice')),
          pw.SizedBox(height: 12),

          // Section 5 - Image
          _sectionHeader('5. Photo Evidence'),
          if (siteImage != null) ...[
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Image(siteImage, width: 400, fit: pw.BoxFit.contain),
            ),
          ] else
            pw.Text('No image captured.', style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _sectionHeader(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          title,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      );

  static pw.Widget _field(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label: ',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.TextSpan(
                text: value,
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      );
}