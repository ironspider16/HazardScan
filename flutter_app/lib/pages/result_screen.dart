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
  static const int idBrokenSteps = 0;
  static const int idLadder = 1;
  static const int idLocked = 2; // hide only
  static const int idScaffolding = 3;
  static const int idUnlocked = 4;

  static const Set<int> hazardIds = {
    idBrokenSteps,
    idUnlocked, 
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
    if (classId == idLocked) return '';

    // Prevent crashes if Gemini returns a classId outside the YOLO list
    if (classId < 0 || classId >= YoloService.classNames.length) {
      return 'Object';
    }
    return YoloService.classNames[classId];
  }

  // Helper to determine what text to show in the bounding box
  String _getBoxLabel(Detection d) {
    if (d.label.isNotEmpty) {
      // If it's a Gemini label, just show the Object Name and Status in the box
      // e.g., "[Ladder] HAZARD" instead of the whole paragraph
      return d.label.split(':').first; 
    }
    return _safeLabel(d.classId);
  }

  // Helper to check if a detection is considered a hazard
  bool _isHazard(Detection d) {
    if (d.label.isNotEmpty) {
      final upperLabel = d.label.toUpperCase();
      return upperLabel.contains("HAZARD") || upperLabel.contains("UNLOCKED");
    }
    return hazardIds.contains(d.classId);
  }

  @override
  Widget build(BuildContext context) {
    final imgSize = _imageSize;

    // Remove locked detections from everything shown
    final visibleDetections =
        widget.detections.where((d) => d.classId != idLocked).toList();

    // Check if we are using Gemini (by checking if any detection has a label)
    final bool isGeminiMode = visibleDetections.any((d) => d.label.isNotEmpty);

    String hazardsText = "";
    String detectedText = "";

    if (isGeminiMode) {
      // --- GEMINI LOGIC ---
      final aiDetection = visibleDetections.firstWhere((d) => d.label.isNotEmpty);
      bool aiFoundHazard = _isHazard(aiDetection);

      if (aiFoundHazard) {
        hazardsText = aiDetection.label;
        detectedText = "Object analyzed by AI";
      } else {
        hazardsText = "None";
        detectedText = aiDetection.label;
      }
    } else {
      // --- YOLO LOGIC (Fallback) ---
      final hazards =
          visibleDetections.where((d) => hazardIds.contains(d.classId)).toList();

      final detectedObjects = visibleDetections
          .where((d) => nonHazardDetectedIds.contains(d.classId))
          .toList();

      hazardsText = hazards.isEmpty
          ? 'No hazards detected. Tip: move closer to the lock/steps and retake.'
          : hazards.map((d) => _safeLabel(d.classId)).where((s) => s.isNotEmpty).toSet().join(', ');

      detectedText = detectedObjects.isEmpty
          ? 'None'
          : detectedObjects
              .map((d) => _safeLabel(d.classId))
              .where((s) => s.isNotEmpty)
              .toSet()
              .join(', ');
    }

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

                    // Draw boxes
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BoundingBoxPainter(
                          detections: visibleDetections,
                          imageSize: imgSize,
                          widgetSize: widgetSize,
                          labelResolver: _getBoxLabel,
                          hazardChecker: _isHazard,
                        ),
                      ),
                    ),

                    // Bottom panel (Detected vs Hazards)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        color: Colors.black87, // Slightly darker for readability
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
                            const SizedBox(height: 10),
                            Text(
                              'Hazards: $hazardsText',
                              style: TextStyle(
                                // Highlight red if a hazard is found
                                color: hazardsText != "None" && !hazardsText.startsWith("No hazards") 
                                    ? Colors.redAccent 
                                    : Colors.white,
                                fontSize: 15,
                                fontWeight: hazardsText != "None" ? FontWeight.bold : FontWeight.normal,
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

  final String Function(Detection d) labelResolver;
  final bool Function(Detection d) hazardChecker;

  BoundingBoxPainter({
    required this.detections,
    required this.imageSize,
    required this.widgetSize,
    required this.labelResolver,
    required this.hazardChecker,
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
      final labelText = labelResolver(d);
      if (labelText.isEmpty) continue;

      final isHazard = hazardChecker(d);

      // Colors: hazards red, objects blue
      paint.color = isHazard ? Colors.redAccent : Colors.lightBlueAccent;

      final left = dx + d.left * scale;
      final top = dy + d.top * scale;
      final right = dx + d.right * scale;
      final bottom = dy + d.bottom * scale;

      final rect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(rect, paint);

      // We only show the short name + confidence in the box to save space
      final text = '$labelText (${d.confidence.toStringAsFixed(2)})';
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            backgroundColor:
                isHazard ? Colors.redAccent : Colors.lightBlueAccent,
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