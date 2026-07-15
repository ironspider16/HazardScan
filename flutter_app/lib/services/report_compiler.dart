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

  // --- MAIN COMPARATIVE GENERATOR ---
  static Future<Uint8List> generateWshReport({
    required String location,
    required String supervisor,
    required String employer,
    required int totalAttempts,
    required String aiChangeExplanation,
    required Map<String, dynamic> initialAiData,
    required Map<String, dynamic> finalAiData,
    required String manualNotes,
    List<Uint8List>? initialImagesBytes,
    List<Uint8List>? finalImagesBytes,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansSymbols2Regular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final String currentDate = DateTime.now().toIso8601String().split('T')[0];
    final String currentTime =
        "${DateTime.now().hour.toString().padLeft(2, '0')}:"
        "${DateTime.now().minute.toString().padLeft(2, '0')}";

    String getField(Map<String, dynamic> block, String field) =>
        block[field]?.toString().trim() ?? 'Not Declared';

    // ─────────────────────────────────────────────────────────────────
    // PAGE 1: AUDIT LOG, SUMMARY AND EVOLUTION MATRIX
    // ─────────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        header: (_) => _pageHeader(currentDate, currentTime),
        footer: (ctx) => _pageFooter(ctx),
        build: (pw.Context context) => [
          pw.SizedBox(height: 16),

          // --- OVERALL STATUS BANNER (Reflects Final Rectified State) ---
          _statusBanner(finalAiData['overallStatus'] ?? 'SAFE'),
          pw.SizedBox(height: 16),

          // --- SECTION 1: Site Details ---
          _sectionHeader('1. Site & Personnel Details'),
          pw.SizedBox(height: 8),
          _infoGrid([
            ['Location', location.isEmpty ? 'Not Declared' : location],
            ['Supervisor', supervisor.isEmpty ? 'Unassigned' : supervisor],
            ['Employer / Contractor', employer.isEmpty ? 'Not Declared' : employer],
            ['Inspection Time', '$currentDate  $currentTime SGT'],
            ['Total Rectification Attempts', '$totalAttempts Attempt(s) to achieve compliance'],
          ]),
          pw.SizedBox(height: 16),

          // --- SECTION 2: AI Intermittent Comparison Summary ---
          _sectionHeader('2. Rectification Summary (AI Insight)'),
          pw.SizedBox(height: 8),
          _aiSummaryBox(aiChangeExplanation),
          pw.SizedBox(height: 16),

          // --- SECTION 3: Safety Metric Evolution Matrix ---
          _sectionHeader('3. Metric Evolution (Before ➔ After)'),
          pw.SizedBox(height: 8),
          _evolutionTable(initialAiData, finalAiData, getField),
          pw.SizedBox(height: 16),

          // Manual notes box if provided
          if (manualNotes.isNotEmpty) ...[
            _notesBox(manualNotes),
            pw.SizedBox(height: 16),
          ],
        ],
      ),
    );

    // ─────────────────────────────────────────────────────────────────
    // PAGE 2: EXCLUSIVE VISUAL COMPARISON LAUNCH WINDOW
    // ─────────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              _pageHeader(currentDate, currentTime),
              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('4. Side-By-Side Evidence Comparison'),
                    pw.SizedBox(height: 16),
                    pw.Container(
                      height: 400,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          // Left column: Before Pane
                          pw.Expanded(
                            child: pw.Column(
                              children: [
                                pw.Container(
                                  width: double.infinity,
                                  color: _red,
                                  padding: const pw.EdgeInsets.all(6),
                                  child: pw.Text(
                                    'INITIAL AUDIT (UNSAFE)',
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _white, fontSize: 9),
                                  ),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Expanded(
                                  child: (initialImagesBytes != null && initialImagesBytes.isNotEmpty)
                                      ? _sideBySideImageFrame(initialImagesBytes.first)
                                      : _emptyPaneFrame('No initial image logged'),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 16),

                          // Right column: After Pane
                          pw.Expanded(
                            child: pw.Column(
                              children: [
                                pw.Container(
                                  width: double.infinity,
                                  color: _green,
                                  padding: const pw.EdgeInsets.all(6),
                                  child: pw.Text(
                                    'RECTIFIED WORKSPACE (SAFE)',
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _white, fontSize: 9),
                                  ),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Expanded(
                                  child: (finalImagesBytes != null && finalImagesBytes.isNotEmpty)
                                      ? _sideBySideImageFrame(finalImagesBytes.first)
                                      : _emptyPaneFrame('No rectification image logged'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              _pageFooter(context),
            ],
          );
        },
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
                'WSH INSPECTION RECTIFICATION REPORT',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _white,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Workplace Safety & Health — Intermittent Compliance Validation Audit',
                style: pw.TextStyle(fontSize: 8, color: _white),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                date,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _white,
                ),
              ),
              pw.Text(
                '$time SGT',
                style: pw.TextStyle(fontSize: 8, color: _white),
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
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CONFIDENTIAL — HazardScan Verification Network',
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
              'FINAL CLOSURE COMPLIANCE STATUS',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _textFaint,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: pw.BoxDecoration(
          color: _blueTint,
          border: const pw.Border(left: pw.BorderSide(color: _blue, width: 4)),
        ),
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _blue,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // INFO GRID
  // ─────────────────────────────────────────
  static pw.Widget _infoGrid(List<List<String>> rows) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.4),
          1: const pw.FlexColumnWidth(2.6),
        },
        children: rows.map((row) {
          return pw.TableRow(
            children: [
              pw.Container(
                color: _greyTint,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: pw.Text(
                  row[0],
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textFaint),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: pw.Text(
                  row[1],
                  style: pw.TextStyle(fontSize: 9, color: _textMain),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────
  // AI RECTIFICATION SUMMARY BOX
  // ─────────────────────────────────────────
  static pw.Widget _aiSummaryBox(String summaryText) {
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
        child: pw.Text(
          summaryText.isEmpty ? "No systemic alteration insights evaluated by intelligence core." : summaryText,
          style: pw.TextStyle(fontSize: 9, color: _textMain, height: 1.4),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // DYNAMIC EVOLUTION MATRIX TABLE
  // ─────────────────────────────────────────
  static pw.Widget _evolutionTable(
    Map<String, dynamic> initial,
    Map<String, dynamic> finalData,
    String Function(Map<String, dynamic>, String) getField,
  ) {
    final modules = [
      ['Working at Heights', 'ladderHeight'],
      ['Personal Protective Equipment', 'ppe'],
      ['Buddy System Requirements', 'buddySystem'],
      ['Electrical & Machinery Safeguards', 'electricalMachinery'],
      ['Housekeeping and Area Hazards', 'areaHazards'],
    ];

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.5),
          1: const pw.FlexColumnWidth(2.5),
        },
        children: [
          // Table Header
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _blue),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('Safety Check Module', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _white, fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('Status Transformation (Initial  ➔  Current Verified)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _white, fontSize: 9)),
              ),
            ],
          ),
          // Rows populated dynamically mapping status evolution
          ...modules.map((mod) {
            final initialBlock = initial[mod[1]] ?? {};
            final finalBlock = finalData[mod[1]] ?? {};
            final beforeStatus = getField(initialBlock, 'compliance').toUpperCase();
            final afterStatus = getField(finalBlock, 'compliance').toUpperCase();

            return pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(mod[0], style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textMain)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    children: [
                      _inlineBadge(beforeStatus),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                        child: pw.Text('➔', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _grey)),
                      ),
                      _inlineBadge(afterStatus),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  static pw.Widget _inlineBadge(String status) {
    final color = _statusColor(status);
    final tint = _statusTint(status);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: tint,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: color, width: 0.5),
      ),
      child: pw.Text(
        status.isEmpty ? 'N/A' : status,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: color),
      ),
    );
  }

  // ─────────────────────────────────────────
  // IMAGE BOX COMPONENT DESIGN
  // ─────────────────────────────────────────
  static pw.Widget _sideBySideImageFrame(Uint8List bytes) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 6,
        verticalRadius: 6,
        child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
      ),
    );
  }

  static pw.Widget _emptyPaneFrame(String instructions) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _greyTint,
        border: pw.Border.all(color: _border, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Center(
        child: pw.Text(instructions, style: pw.TextStyle(fontSize: 9, color: _textFaint)),
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
            pw.Text(notes, style: pw.TextStyle(fontSize: 9, color: _textMain)),
          ],
        ),
      ),
    );
  }
}