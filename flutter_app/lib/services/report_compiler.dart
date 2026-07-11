import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LocalReportCompiler {
  // --- COLOUR PALETTE (mirrors app theme) ---
  static const PdfColor _blue = PdfColor.fromInt(0xFF1A56DB);
  static const PdfColor _blueTint = PdfColor.fromInt(0xFFEBF2FF);
  static const PdfColor _red = PdfColor.fromInt(0xFFB91C1C);
  static const PdfColor _redTint = PdfColor.fromInt(0xFFFEE2E2);
  static const PdfColor _orange = PdfColor.fromInt(0xFFC2410C);
  static const PdfColor _orangeTint = PdfColor.fromInt(0xFFFFEDD5);
  static const PdfColor _green = PdfColor.fromInt(0xFF15803D);
  static const PdfColor _greenTint = PdfColor.fromInt(0xFFDCFCE7);
  static const PdfColor _grey = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _greyTint = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor _white = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _textMain = PdfColor.fromInt(0xFF111827);
  static const PdfColor _textFaint = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _border = PdfColor.fromInt(0xFFE5E7EB);

  // --- STATUS HELPERS ---
  static PdfColor _statusColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'DANGEROUS':
        return _red;
      case 'SAFE':
        return _green;
      default:
        return _grey;
    }
  }

  static PdfColor _statusTint(String status) {
    switch (status.trim().toUpperCase()) {
      case 'DANGEROUS':
        return _redTint;
      case 'SAFE':
        return _greenTint;
      default:
        return _greyTint;
    }
  }

  // --- MAIN GENERATOR ---
  static Future<Uint8List> generateWshReport({
    required String location,
    required String supervisor,
    required String employer,
    required Map<String, dynamic> initialAiData,
    required String manualNotes,
    List<Uint8List>? imagesBytes,
    String? submittedAt,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();

    // Extract blocks
    final Map<String, dynamic> ladder = initialAiData['ladderHeight'] ?? {};
    final Map<String, dynamic> ppe = initialAiData['ppe'] ?? {};
    final Map<String, dynamic> buddy = initialAiData['buddySystem'] ?? {};
    final Map<String, dynamic> electrical = initialAiData['electricalMachinery'] ?? {};
    final Map<String, dynamic> hazards = initialAiData['areaHazards'] ?? {};
    final String overallStatus = initialAiData['overallStatus'] ?? 'PENDING';

    String getField(Map<String, dynamic> block, String field) =>
        block[field]?.toString().trim() ?? 'Not Declared';

    final String currentDate =
        submittedAt ?? DateTime.now().toIso8601String().split('T')[0];
    final String currentTime = submittedAt != null
        ? ''
        : "${DateTime.now().hour.toString().padLeft(2, '0')}:"
              "${DateTime.now().minute.toString().padLeft(2, '0')}";

    // Convert all captured image streams into a PDF layout array
    List<pw.MemoryImage> siteImages = [];
    if (imagesBytes != null) {
      siteImages = imagesBytes.map((bytes) => pw.MemoryImage(bytes)).toList();
    }

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        header: (_) => _pageHeader(currentDate, currentTime),
        footer: (ctx) => _pageFooter(ctx),
        build: (pw.Context context) => [
          pw.SizedBox(height: 16),

          // --- OVERALL STATUS BANNER ---
          _statusBanner(overallStatus),
          pw.SizedBox(height: 16),

          // --- SECTION 1: Site Details ---
          _sectionHeader('1. Site & Personnel Details'),
          pw.SizedBox(height: 8),
          _infoGrid([
            ['Location', location.isEmpty ? 'Not Declared' : location],
            ['Supervisor', supervisor.isEmpty ? 'Unassigned' : supervisor],
            [
              'Employer / Contractor',
              employer.isEmpty ? 'Not Declared' : employer,
            ],
            [
              'Inspection Time',
              '$currentDate  $currentTime ${submittedAt != null ? '' : 'SGT'}',
            ],
          ]),
          pw.SizedBox(height: 16),

          // --- SECTION 2: Hazard Identification ---
          _sectionHeader('2. Hazard Identification'),
          pw.SizedBox(height: 8),
          _hazardCard('Working at Heights', ladder, getField),
          pw.SizedBox(height: 8),
          _hazardCard('Personal Protective Equipment (PPE)', ppe, getField),
          pw.SizedBox(height: 8),
          _hazardCard('Buddy System', buddy, getField),
          pw.SizedBox(height: 8),
          _hazardCard('Electrical & Machinery Hazards', electrical, getField),
          pw.SizedBox(height: 8),
          _hazardCard('Housekeeping and Area Hazards', hazards, getField),
          pw.SizedBox(height: 8),

          // Manual notes box
          if (manualNotes.isNotEmpty) ...[
            _notesBox(manualNotes),
            pw.SizedBox(height: 16),
          ] else
            pw.SizedBox(height: 8),

          // --- SECTION 3: Photo Evidence ---
          _sectionHeader('3. Photo Evidence'),
          pw.SizedBox(height: 8),
          if (siteImages.isNotEmpty) ...[
            pw.Column(
              children: siteImages
                  .map(
                    (img) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 12),
                      child: _imageBlock(img),
                    ),
                  )
                  .toList(),
            ),
          ] else
            _emptyImageBlock(),

          pw.SizedBox(height: 24),
        ],
      ),
    );

    return pdf.save();
  }

  // ─────────────────────────────────────────
  // PAGE HEADER
  // ─────────────────────────────────────────
  static pw.Widget _pageHeader(String date, String time) {
    return pw.Container(
      color: _blue,
      padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'WSH INSPECTION REPORT',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _white,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Workplace Safety & Health — Site Audit',
                style: pw.TextStyle(fontSize: 9, color: _white),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                date,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _white,
                ),
              ),
              pw.Text(
                '$time SGT',
                style: pw.TextStyle(fontSize: 9, color: _white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // PAGE FOOTER
  // ─────────────────────────────────────────
  static pw.Widget _pageFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CONFIDENTIAL — WSH Inspection Report',
            style: pw.TextStyle(fontSize: 8, color: _textFaint),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _textFaint),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // STATUS BANNER
  // ─────────────────────────────────────────
  static pw.Widget _statusBanner(String status) {
    final color = _statusColor(status);
    final tint = _statusTint(status);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: pw.BoxDecoration(
          color: tint,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: color, width: 1.5),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'OVERALL COMPLIANCE STATUS',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _textFaint,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                status.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // SECTION HEADER
  // ─────────────────────────────────────────
  static pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: pw.BoxDecoration(
          color: _blueTint,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColors.blue, width: 2),
        ),
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _blue,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // INFO GRID (2-column layout for site details)
  // ─────────────────────────────────────────
  static pw.Widget _infoGrid(List<List<String>> rows) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.2),
          1: const pw.FlexColumnWidth(2.8),
        },
        children: rows.map((row) {
          return pw.TableRow(
            children: [
              pw.Container(
                color: _greyTint,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: pw.Text(
                  row[0],
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _textFaint,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: pw.Text(
                  row[1],
                  style: pw.TextStyle(fontSize: 10, color: _textMain),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────
  // HAZARD CARD
  // ─────────────────────────────────────────
  static pw.Widget _hazardCard(
    String title,
    Map<String, dynamic> block,
    String Function(Map<String, dynamic>, String) getField,
  ) {
    final compliance = getField(block, 'compliance');
    final color = _statusColor(compliance);
    final tint = _statusTint(compliance);

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _border, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Card header row
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: _greyTint,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _textMain,
                    ),
                  ),
                  // Compliance badge
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: tint,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                      border: pw.Border.all(color: color, width: 0.5),
                    ),
                    child: pw.Text(
                      compliance.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Description
            _cardRow('Observation', getField(block, 'description'), false),
            _cardRow('Reasoning', getField(block, 'reasoning'), false),

            // Advice row — highlighted
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: _blueTint,
                border: pw.Border.all(color: _border, width: 0.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CORRECTIVE ADVICE',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _blue,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    getField(block, 'advice'),
                    style: pw.TextStyle(fontSize: 9, color: _textMain),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // CARD ROW (inside hazard card)
  // ─────────────────────────────────────────
  static pw.Widget _cardRow(String label, String value, bool isLast) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _textFaint,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 9, color: _textMain),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // MANUAL NOTES BOX
  // ─────────────────────────────────────────
  static pw.Widget _notesBox(String notes) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _greyTint,
          border: pw.Border.all(color: _border, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'SITE CONTEXT & MANUAL NOTES',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _textFaint,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(notes, style: pw.TextStyle(fontSize: 10, color: _textMain)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // IMAGE BLOCK
  // ─────────────────────────────────────────
  static pw.Widget _imageBlock(pw.MemoryImage image) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _border, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.ClipRRect(
          horizontalRadius: 6,
          verticalRadius: 6,
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }

  static pw.Widget _emptyImageBlock() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Container(
        height: 60,
        decoration: pw.BoxDecoration(
          color: _greyTint,
          border: pw.Border.all(color: _border, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Center(
          child: pw.Text(
            'No site image captured.',
            style: pw.TextStyle(fontSize: 10, color: _textFaint),
          ),
        ),
      ),
    );
  }
}
