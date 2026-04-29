import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/detection.dart';
import '../services/yolo_service.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final List<Detection> detections;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.detections,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Size? _imageSize;

  // IDs based on your trained YAML order:
  // 0 broken steps, 1 ladder, 2 locked, 3 scaffolding, 4 unlocked
 static const int idBrokenSteps = 0;
static const int idLadder = 1;
static const int idLocked = 2;        // hide only
static const int idScaffolding = 3;
static const int idUnlocked = 4;

  static const Set<int> hazardIds = {
  idBrokenSteps,
  idUnlocked,   // ← THIS was missing
};

  static const Set<int> nonHazardDetectedIds = {idLadder, idScaffolding};

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    if (!mounted) return;
    setState(() {
      _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
    });
  }

  String _safeLabel(int classId) {
    // Hide "locked" from display completely
    if (classId == idLocked) return '';

    if (classId < 0 || classId >= YoloService.classNames.length) {
      return 'unknown($classId)';
    }
    return YoloService.classNames[classId];
  }

  @override
  Widget build(BuildContext context) {
    final imgSize = _imageSize;

    // 🔎 DEBUG: raw detections coming from YOLO (before UI filtering)
  for (final d in widget.detections) {
    debugPrint(
      'RAW DETECTION → '
      'id=${d.classId} '
      'label=${YoloService.classNames[d.classId]} '
      'conf=${d.confidence.toStringAsFixed(2)}',
    );
  }

    // Remove locked detections from everything shown
    final visibleDetections =
    widget.detections.where((d) => d.classId != idLocked).toList();


    // Hazards list (for hazards panel)
    final hazards =
        visibleDetections.where((d) => hazardIds.contains(d.classId)).toList();

    // Non-hazard detections list (ladder/scaffolding)
    final detectedObjects = visibleDetections
        .where((d) => nonHazardDetectedIds.contains(d.classId))
        .toList();

    final hazardsText = hazards.isEmpty
        ? 'No hazards detected. Tip: move closer to the lock/steps and retake.'
        : hazards.map((d) => _safeLabel(d.classId)).where((s) => s.isNotEmpty).toSet().join(', ');

    final detectedText = detectedObjects.isEmpty
        ? 'None'
        : detectedObjects
            .map((d) => _safeLabel(d.classId))
            .where((s) => s.isNotEmpty)
            .toSet()
            .join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      backgroundColor: Colors.black,
      body: imgSize == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final widgetSize =
                    Size(constraints.maxWidth, constraints.maxHeight);

                return Stack(
                  children: [
                    // Photo
                    Positioned.fill(
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),

                    // ✅ Draw boxes for ladder + scaffolding + hazards (locked hidden)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BoundingBoxPainter(
                          detections: visibleDetections,
                          imageSize: imgSize,
                          widgetSize: widgetSize,
                          labelOf: _safeLabel,
                          // Colour hazards red, others blue
                          isHazard: (id) => hazardIds.contains(id),
                        ),
                      ),
                    ),

                    // Bottom panel (Detected vs Hazards)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        color: Colors.black54,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detected: $detectedText',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Hazards detected: $hazardsText',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize;
  final Size widgetSize;

  final String Function(int classId) labelOf;
  final bool Function(int classId) isHazard;

  BoundingBoxPainter({
    required this.detections,
    required this.imageSize,
    required this.widgetSize,
    required this.labelOf,
    required this.isHazard,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return;

    // BoxFit.contain mapping
    final scale = min(
      widgetSize.width / imageSize.width,
      widgetSize.height / imageSize.height,
    );

    final displayW = imageSize.width * scale;
    final displayH = imageSize.height * scale;

    final dx = (widgetSize.width - displayW) / 2;
    final dy = (widgetSize.height - displayH) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final d in detections) {
      final label = labelOf(d.classId);
      if (label.isEmpty) continue; // hides locked + anything you choose

      // Colors: hazards red, objects blue
      paint.color = isHazard(d.classId) ? Colors.redAccent : Colors.lightBlueAccent;

      final left = dx + d.left * scale;
      final top = dy + d.top * scale;
      final right = dx + d.right * scale;
      final bottom = dy + d.bottom * scale;

      final rect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(rect, paint);

      final text = '$label (${d.confidence.toStringAsFixed(2)})';
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            backgroundColor:
                isHazard(d.classId) ? Colors.redAccent : Colors.lightBlueAccent,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: widgetSize.width);

      final labelX = rect.left.clamp(0.0, widgetSize.width - tp.width);
      final labelY =
          (rect.top - tp.height - 2).clamp(0.0, widgetSize.height - tp.height);

      tp.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.widgetSize != widgetSize;
  }
}
