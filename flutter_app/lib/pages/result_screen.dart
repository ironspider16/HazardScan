import 'dart:math';
import 'package:flutter/material.dart';
import '../models/detection.dart';
import 'dart:typed_data';

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

  bool _isHazard(Detection d) {
    final label = d.label.toLowerCase();
    return label.contains("spreader_unlock");
  }

  String _getBoxLabel(Detection d) {
    return "${d.label} ${(d.confidence * 100).toStringAsFixed(1)}%";
  }

  @override
  Widget build(BuildContext context) {
    final imgSize = _imageSize;

    // You only have 2 classes: ladder and spreader_unlock
    final visibleDetections = widget.detections;

    String detectedText = "No objects identified";
    String hazardsText = "None";

    if (visibleDetections.isNotEmpty) {
      detectedText = visibleDetections
          .map((d) => "${d.label} ${(d.confidence * 100).toStringAsFixed(1)}%")
          .join(", ");

      final hazardDetections = visibleDetections.where(_isHazard).toList();

      if (hazardDetections.isNotEmpty) {
        hazardsText = "Ladder spreader is unlocked";
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
                    Positioned.fill(
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                      ),
                    ),

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
                              'Detected: $detectedText',
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

    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final d in detections) {
      final isHazard = hazardChecker(d);
      boxPaint.color = isHazard ? Colors.redAccent : Colors.lightBlueAccent;

      final rect = Rect.fromLTRB(
        dx + d.left * scale,
        dy + d.top * scale,
        dx + d.right * scale,
        dy + d.bottom * scale,
      );

      canvas.drawRect(rect, boxPaint);

      final label = labelResolver(d);

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            backgroundColor: isHazard ? Colors.redAccent : Colors.blueAccent,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final labelOffset = Offset(
        rect.left,
        max(0, rect.top - textPainter.height),
      );

      textPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) => true;
}
