import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/detection.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'camera_page.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final Uint8List imageBytes;
  final List<Detection> detections;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.detections,
    required this.imageBytes,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Size? _imageSize;

  // Local Class Definitions (No longer relying on YoloService)
  static const List<String> classNames = [
    'Broken Steps',
    'Ladder',
    'Locked',
    'Scaffolding',
    'Unlocked',
  ];

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final decoded = await decodeImageFromList(widget.imageBytes);

    if (!mounted) return;

    setState(() {
      _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
    });
  }

  // Helper to determine what text to show in the bounding box
  String _getBoxLabel(Detection d) {
    if (d.label.isNotEmpty) {
      // Takes the first part of Gemini's response for the overlay
      // e.g. "[Ladder] HAZARD"
      return d.label.split(':').first;
    }
    return "Object";
  }

  // Logic to determine if the AI found a hazard
  bool _isHazard(Detection d) {
    final upperLabel = d.label.toUpperCase();
    return upperLabel.contains("HAZARD") ||
        upperLabel.contains("UNLOCKED") ||
        upperLabel.contains("BROKEN");
  }

  @override
  Widget build(BuildContext context) {
    final imgSize = _imageSize;

    // Filter out "LOCKED" (Safe) status to keep UI clean
    final visibleDetections = widget.detections
        .where((d) => !d.label.toUpperCase().contains("LOCKED"))
        .toList();

    String hazardsText = "None";
    String detectedText = "No objects identified";

    if (visibleDetections.isNotEmpty) {
      final aiResult = visibleDetections.first;
      bool foundHazard = _isHazard(aiResult);

      if (foundHazard) {
        hazardsText = aiResult.label; // Show full Gemini Reason
        detectedText = "Analysis Complete";
      } else {
        hazardsText = "None";
        detectedText = aiResult.label; // Show full Gemini Reason
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analysis Result'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: imgSize == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : LayoutBuilder(
              builder: (context, constraints) {
                final widgetSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return Stack(
                  children: [
                    // The Photo
                    Positioned.fill(
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Draw AI Overlays
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

                    // Bottom Panel with Detailed AI Reasoning
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI DETECTION LOG',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Status: $detectedText',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const Divider(color: Colors.white24, height: 20),
                            Text(
                              'Safety Analysis:',
                              style: TextStyle(
                                color: hazardsText != "None"
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              hazardsText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.4,
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

    final scale = min(
      widgetSize.width / imageSize.width,
      widgetSize.height / imageSize.height,
    );
    final dx = (widgetSize.width - imageSize.width * scale) / 2;
    final dy = (widgetSize.height - imageSize.height * scale) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final d in detections) {
      // Logic: If Gemini provides a full-screen analysis (0,0 to 1,1),
      // we don't draw a box because it blocks the view.
      if (d.left == 0.0 && d.top == 0.0 && d.right == 1.0) continue;

      final isHazard = hazardChecker(d);
      paint.color = isHazard ? Colors.redAccent : Colors.lightBlueAccent;

      final rect = Rect.fromLTRB(
        dx + d.left * scale,
        dy + d.top * scale,
        dx + d.right * scale,
        dy + d.bottom * scale,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) => true;
}
