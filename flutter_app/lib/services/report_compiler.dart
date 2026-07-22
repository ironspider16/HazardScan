import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LocalReportCompiler {
  // ─── COLOUR PALETTE ──────────────────────────────────────────────────────
  static const PdfColor _blue      = PdfColor.fromInt(0xFF1A56DB);
  static const PdfColor _blueTint  = PdfColor.fromInt(0xFFEBF2FF);
  static const PdfColor _red       = PdfColor.fromInt(0xFFB91C1C);
  static const PdfColor _redTint   = PdfColor.fromInt(0xFFFEE2E2);
  static const PdfColor _green     = PdfColor.fromInt(0xFF15803D);
  static const PdfColor _greenTint = PdfColor.fromInt(0xFFDCFCE7);
  static const PdfColor _grey      = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _greyTint  = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor _white     = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _textMain  = PdfColor.fromInt(0xFF111827);
  static const PdfColor _textFaint = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _border    = PdfColor.fromInt(0xFFE5E7EB);

  static PdfColor _statusColor(String s) {
    switch (s.trim().toUpperCase()) {
      case 'DANGEROUS': return _red;
      case 'SAFE':      return _green;
      default:          return _grey;
    }
  }

  static PdfColor _statusTint(String s) {
    switch (s.trim().toUpperCase()) {
      case 'DANGEROUS': return _redTint;
      case 'SAFE':      return _greenTint;
      default:          return _greyTint;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MAIN ENTRY POINT
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> generateWshReport({
    required String location,
    required String technician,
    required String employer,
    required int totalAttempts,
    required String aiChangeAnalysis,
    required Map<String, dynamic> initialAiData,
    required Map<String, dynamic> finalAiData,
    required String manualNotes,
    bool? spreaderUnlocked,
    int? initialAnalysisId,
    String? submittedAt,
    List<Uint8List>? initialImagesBytes,
    List<Uint8List>? finalImagesBytes,
  }) async {
    final pdf      = pw.Document();
    final font     = await PdfGoogleFonts.notoSansSymbols2Regular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final String headerDate = submittedAt != null
        ? submittedAt.split('T')[0]
        : DateTime.now().toIso8601String().split('T')[0];
    final String headerTime = submittedAt != null
        ? submittedAt.contains('T')
            ? submittedAt.split('T')[1].substring(0, 5)
            : ''
        : '${DateTime.now().hour.toString().padLeft(2, '0')}:'
          '${DateTime.now().minute.toString().padLeft(2, '0')}';

    final bool isComparative = totalAttempts > 1;

    String getField(Map<String, dynamic> block, String field) =>
        block[field]?.toString().trim() ?? 'Not Declared';

    final pw.ThemeData theme = pw.ThemeData.withFont(base: font, bold: fontBold);

    // ─────────────────────────────────────────────────────────────────────
    // PAGE 1 — SUMMARY, EVOLUTION MATRIX, NOTES
    // ─────────────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        header: (_) => _pageHeader(headerDate, headerTime),
        footer: (ctx) => _pageFooter(ctx),
        build: (_) => [
          pw.SizedBox(height: 16),
          _statusBanner(finalAiData['overallStatus'] ?? 'SAFE'),
          pw.SizedBox(height: 16),

          // Section 1 — Site details
          _sectionHeader('1. Site & Personnel Details'),
          pw.SizedBox(height: 8),
          _infoGrid([
            ['Location',              location.isEmpty   ? 'Not Declared' : location],
            ['technician',            technician.isEmpty ? 'Unassigned'   : technician],
            ['Employer / Contractor', employer.isEmpty   ? 'Not Declared' : employer],
            ['Inspection Time',       '$headerDate  $headerTime SGT'],
            ['Rectification Attempts', isComparative
                ? '$totalAttempts Attempt(s) required to achieve compliance'
                : 'Site passed on first analysis — no rectification required'],
          ]),
          pw.SizedBox(height: 16),

          // Section 2 — AI summary
          _sectionHeader(
            isComparative
                ? '2. Rectification Summary (AI Insight)'
                : '2. First-Pass Compliance Notice',
          ),
          pw.SizedBox(height: 8),
          _aiSummaryBox(
            isComparative
                ? aiChangeAnalysis
                : 'The workspace was assessed as fully compliant on the first inspection pass. '
                  'No corrective action was required. All safety categories met the required '
                  'standard without any intermediate rectification steps.',
          ),
          pw.SizedBox(height: 16),

          // Section 3 — Evolution matrix (comparative only)
          if (isComparative) ...[
            _sectionHeader('3. Metric Evolution (Before  =>  After)'),
            pw.SizedBox(height: 8),
            _evolutionTable(initialAiData, finalAiData, getField),
            pw.SizedBox(height: 16),
          ],

          // Manual notes (truncated at 600 chars to prevent page 1 overflow)
          if (manualNotes.isNotEmpty) ...[
            _notesBox(
              manualNotes.length > 600
                  ? '${manualNotes.substring(0, 600)}… [truncated]'
                  : manualNotes,
            ),
            pw.SizedBox(height: 16),
          ],
        ],
      ),
    );

    // ─────────────────────────────────────────────────────────────────────
    // PAGE 2 — INITIAL INSPECTION HAZARD DETAILS
    // Uses pw.Table per category so MultiPage can break at row boundaries —
    // prevents near-empty overflow pages caused by long reasoning text.
    // ─────────────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        header: (_) => _pageHeader(headerDate, headerTime),
        footer: (ctx) => _pageFooter(ctx),
        build: (_) => [
          pw.SizedBox(height: 16),
          _sectionHeader(
            isComparative
                ? '4. Initial Inspection — Hazard Identification'
                : '3. Hazard Identification & Assessment',
          ),
          pw.SizedBox(height: 8),
          _passLabel(
            isComparative
                ? 'INITIAL AUDIT PASS — UNSAFE STATE'
                : 'SINGLE PASS — COMPLIANT STATE',
            isComparative ? _red   : _green,
            isComparative ? _redTint : _greenTint,
          ),
          pw.SizedBox(height: 12),
          ..._hazardDetailWidgets(initialAiData, getField),
        ],
      ),
    );

    // ─────────────────────────────────────────────────────────────────────
    // PAGE 3 — RECTIFIED HAZARD DETAILS (comparative only)
    // ─────────────────────────────────────────────────────────────────────
    if (isComparative) {
      pdf.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          header: (_) => _pageHeader(headerDate, headerTime),
          footer: (ctx) => _pageFooter(ctx),
          build: (_) => [
            pw.SizedBox(height: 16),
            _sectionHeader('5. Rectified Inspection — Verified Safe State'),
            pw.SizedBox(height: 8),
            _passLabel('RECTIFIED AUDIT PASS — SAFE STATE', _green, _greenTint),
            pw.SizedBox(height: 12),
            ..._hazardDetailWidgets(finalAiData, getField),
          ],
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────────────
    // LAST PAGE — IMAGE EVIDENCE (fixed pw.Page, not MultiPage)
    // ─────────────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) => pw.Column(
          children: [
            _pageHeader(headerDate, headerTime),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(32, 16, 32, 0),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      isComparative
                          ? '6. Side-By-Side Visual Evidence Comparison'
                          : '4. Site Evidence Photography',
                    ),
                    pw.SizedBox(height: 12),

                    // Image area — expands to fill remaining page
                    pw.Expanded(
                      child: isComparative
                          ? pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                              children: [
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                                    children: [
                                      _imageColumnHeader('INITIAL AUDIT (UNSAFE)', _red),
                                      pw.SizedBox(height: 6),
                                      pw.Expanded(
                                        child: _imageStack(initialImagesBytes ?? []),
                                      ),
                                    ],
                                  ),
                                ),
                                pw.SizedBox(width: 12),
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                                    children: [
                                      _imageColumnHeader('RECTIFIED WORKSPACE (SAFE)', _green),
                                      pw.SizedBox(height: 6),
                                      pw.Expanded(
                                        child: _imageStack(finalImagesBytes ?? []),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                              children: [
                                _imageColumnHeader('SITE EVIDENCE — COMPLIANT STATE', _green),
                                pw.SizedBox(height: 6),
                                pw.Expanded(
                                  child: _imageStack(initialImagesBytes ?? []),
                                ),
                              ],
                            ),
                    ),

                    pw.SizedBox(height: 10),
                    // Disclaimer note
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: _greyTint,
                        border: pw.Border.all(color: _border, width: 0.5),
                      ),
                      child: pw.Text(
                        isComparative
                            ? 'Representative images from the initial and rectified inspection passes are shown. '
                              'All analysis attempts were logged to the HazardScan audit database. '
                              'Intermediate pass images are not included in this report.'
                            : 'Site evidence captured during the single compliant inspection pass.',
                        style: pw.TextStyle(fontSize: 7, color: _textFaint),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _pageFooter(ctx),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HAZARD DETAIL WIDGETS
  // Each category renders as a pw.Table so MultiPage can break at row
  // boundaries instead of pushing entire cards to the next page.
  // ─────────────────────────────────────────────────────────────────────────
  static List<pw.Widget> _hazardDetailWidgets(
    Map<String, dynamic> aiData,
    String Function(Map<String, dynamic>, String) getField,
  ) {
    final categories = [
      ['Working at Heights',               'ladderHeight'],
      ['Personal Protective Equipment',     'ppe'],
      ['Buddy System Requirements',         'buddySystem'],
      ['Electrical & Machinery Safeguards', 'electricalMachinery'],
      ['Housekeeping and Area Hazards',     'areaHazards'],
    ];

    final List<pw.Widget> widgets = [];

    for (final cat in categories) {
      final block      = aiData[cat[1]] as Map<String, dynamic>? ?? {};
      final compliance = getField(block, 'compliance').toUpperCase();
      final color      = _statusColor(compliance);
      final tint       = _statusTint(compliance);

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 32),
          child: pw.Table(
            border: pw.TableBorder.all(color: _border, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(110),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              // Category header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: tint),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: pw.Text(
                      cat[0],
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _textMain,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: _inlineBadge(compliance),
                    ),
                  ),
                ],
              ),
              // Observation row
              _fieldRow(
                'Observation',
                getField(block, 'description'),
                isHeader: false,
              ),
              // Reasoning row
              _fieldRow(
                'Reasoning',
                getField(block, 'reasoning'),
                isHeader: false,
              ),
              // Corrective Action row
              _fieldRow(
                'Corrective Action',
                getField(block, 'advice'),
                isHeader: false,
              ),
            ],
          ),
        ),
      );
      widgets.add(pw.SizedBox(height: 10));
    }

    return widgets;
  }

  // Single data row inside a category table
  static pw.TableRow _fieldRow(String label, String value, {bool isHeader = false}) {
    return pw.TableRow(
      children: [
        pw.Container(
          color: _greyTint,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _textFaint,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 8, color: _textMain, lineSpacing: 2),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASS LABEL BANNER
  // ─────────────────────────────────────────────────────────────────────────
  static pw.Widget _passLabel(String text, PdfColor color, PdfColor tint) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: pw.BoxDecoration(
          color: tint,
          border: pw.Border.all(color: color, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE STACK — 1 or 2 images stacked vertically
  // ─────────────────────────────────────────────────────────────────────────
  static pw.Widget _imageStack(List<Uint8List> images) {
    if (images.isEmpty) return _emptyPaneFrame('No image captured');
    if (images.length == 1) return _imageFrame(images[0]);
    return pw.Column(
      children: [
        pw.Expanded(child: _imageFrame(images[0])),
        pw.SizedBox(height: 8),
        pw.Expanded(child: _imageFrame(images[1])),
      ],
    );
  }

  static pw.Widget _imageFrame(Uint8List bytes) {
    return pw.ClipRRect(
      horizontalRadius: 4,
      verticalRadius: 4,
      child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
    );
  }

  static pw.Widget _emptyPaneFrame(String message) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _greyTint,
        border: pw.Border.all(color: _border, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Center(
        child: pw.Text(message, style: pw.TextStyle(fontSize: 9, color: _textFaint)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE COLUMN HEADER
  // ─────────────────────────────────────────────────────────────────────────
  static pw.Widget _imageColumnHeader(String text, PdfColor color) {
    return pw.Container(
      width: double.infinity,
      color: color,
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: _white,
          fontSize: 9,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE HEADER
  // ─────────────────────────────────────────────────────────────────────────
  static pw.Widget _pageHeader(String date, String time) {
    return pw.Container(
      color: _blue,
      padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'WSH INSPECTION RECTIFICATION REPORT',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _white,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Workplace Safety & Health — Intermittent Compliance Validation Audit',
                style: pw.TextStyle(fontSize: 7.5, color: _white),
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
              pw.Text('$time SGT', style: pw.TextStyle(fontSize: 7.5, color: _white)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE FOOTER
  // ─────────────────────────────────────────────────────────────────────────
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
            style: pw.TextStyle(fontSize: 7.5, color: _textFaint),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 7.5, color: _textFaint),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS BANNER
  // ─────────────────────────────────────────────────────────────────────────
  static pw.Widget _statusBanner(String status) {
    final color = _statusColor(status);
    final tint  = _statusTint(status);
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

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION HEADER
  // ─────────────────────────────────────────────────────────────────────────
  static pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: const pw.BoxDecoration(
          color: _blueTint,
          border: pw.Border(left: pw.BorderSide(color: _blue, width: 4)),
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

  // ─────────────────────────────────────────────────────────────────────────
  // INFO GRID (site details table)
  // ─────────────────────────────────────────────────────────────────────────
  static pw.Widget _infoGrid(List<List<String>> rows) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.4),
          1: pw.FlexColumnWidth(2.6),
        },
        children: rows.map((row) {
          return pw.TableRow(
            children: [
              pw.Container(
                color: _greyTint,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: pw.Text(
                  row[0],
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _textFaint,
                  ),
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

  // ─────────────────────────────────────────────────────────────────────────
  // AI SUMMARY BOX
  // ─────────────────────────────────────────────────────────────────────────
  static pw.Widget _aiSummaryBox(String text) {
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
          text.isEmpty ? 'Analysis marked as safe on first attempt, No comparison can be made.' : text,
          style: pw.TextStyle(fontSize: 9, color: _textMain, lineSpacing: 2),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EVOLUTION MATRIX TABLE
  // ─────────────────────────────────────────────────────────────────────────
  static pw.Widget _evolutionTable(
    Map<String, dynamic> initial,
    Map<String, dynamic> finalData,
    String Function(Map<String, dynamic>, String) getField,
  ) {
    final modules = [
      ['Working at Heights',               'ladderHeight'],
      ['Personal Protective Equipment',     'ppe'],
      ['Buddy System Requirements',         'buddySystem'],
      ['Electrical & Machinery Safeguards', 'electricalMachinery'],
      ['Housekeeping and Area Hazards',     'areaHazards'],
    ];

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.6),
          1: pw.FlexColumnWidth(2.4),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _blue),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'Safety Check Module',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: _white,
                    fontSize: 9,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'Status Transformation (Initial => Verified)',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: _white,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          ...modules.map((mod) {
            final initialBlock = initial[mod[1]]   as Map<String, dynamic>? ?? {};
            final finalBlock   = finalData[mod[1]] as Map<String, dynamic>? ?? {};
            final before = getField(initialBlock, 'compliance').toUpperCase();
            final after  = getField(finalBlock,   'compliance').toUpperCase();

            return pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: pw.Text(
                    mod[0],
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _textMain,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: pw.Row(
                    children: [
                      _inlineBadge(before),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                        child: pw.Text(
                          '=>',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _grey,
                          ),
                        ),
                      ),
                      _inlineBadge(after),
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

  // ─────────────────────────────────────────────────────────────────────────
  // INLINE STATUS BADGE
  // ─────────────────────────────────────────────────────────────────────────
  static pw.Widget _inlineBadge(String status) {
    final color = _statusColor(status);
    final tint  = _statusTint(status);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: tint,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: color, width: 0.5),
      ),
      child: pw.Text(
        status.isEmpty ? 'N/A' : status,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTES BOX
  // ─────────────────────────────────────────────────────────────────────────
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
            pw.Text(notes, style: pw.TextStyle(fontSize: 9, color: _textMain, lineSpacing: 2)),
          ],
        ),
      ),
    );
  }
}