import 'dart:io';
import 'package:flutter/material.dart';
import '../services/yolo_service.dart';
import 'result_screen.dart';

class ImageConfirmScreen extends StatelessWidget {
  final String imagePath;

  const ImageConfirmScreen({
    super.key,
    required this.imagePath,
  });

  Future<void> _runYolo(BuildContext context) async {
    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final yolo = YoloService();
final detections = await yolo.detectOnImageWithLadderCrop(
  imagePath,
  ladderConf: 0.25,
  hazardConf: 0.08,   // small hazards
  iouThreshold: 0.35,
  cropPadding: 0.25,
);


      if (context.mounted) Navigator.pop(context); // close loading

      // Go to results screen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              imagePath: imagePath,
              detections: detections,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // close loading

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('YOLO failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);

    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Image")),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Retake", style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _runYolo(context),
                    child: const Text("Analyze", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
