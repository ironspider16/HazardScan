import "package:flutter/material.dart";
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:kkhazardscan/models/detection.dart';
import 'package:kkhazardscan/pages/result_screen.dart';


class YoloService {
  Future<void> coldStart() async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          "https://hazardscan-yolo-663409506217.asia-southeast1.run.app/detect",
        ),
      );

      request.fields['model'] = 'yolov8n';

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      print("Cold Start Status: ${response.statusCode}");
      print("Cold Start Response: $responseString");
    } catch (e) {
      print("Cold Start Error: $e");
    }
  }

  Future<List<dynamic>> runYoloDetect({
    required Uint8List imageBytes,
    required bool Function() isMounted,
    required BuildContext context
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          "https://hazardscan-yolo-663409506217.asia-southeast1.run.app/detect",
        ),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: "upload.jpg",
        ),
      );

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final data = jsonDecode(responseString);
      final List detectionsJson = data['detections'] ?? [];

      debugPrint(detectionsJson.toString());

      return detectionsJson.map((item) {
        return {
          'label': item['label'],
          'confidence': item['confidence'].toDouble(),
          'left': item['x1'].toDouble(),
          'top': item['y1'].toDouble(),
          'right': item['x2'].toDouble(),
          'bottom': item['y2'].toDouble(),
        };
      }).toList();
    } catch (e) {
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("YOLO analysis failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  Future<void> yoloDetect(
    BuildContext context,
    Uint8List imageBytes,
    String imagePath,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          "https://hazardscan-yolo-663409506217.asia-southeast1.run.app/detect",
        ),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: "upload.jpg",
        ),
      );

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      print("Status: ${response.statusCode}");
      print("Response: $responseString");

      if (context.mounted) Navigator.pop(context);

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final data = jsonDecode(responseString);
      final List detectionsJson = data['detections'];

      final detections = detectionsJson.map((item) {
        return Detection(
          label: item['label'],
          confidence: item['confidence'].toDouble(),
          left: item['x1'].toDouble(),
          top: item['y1'].toDouble(),
          right: item['x2'].toDouble(),
          bottom: item['y2'].toDouble(),
        );
      }).toList();

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              imagePath: imagePath,
              imageBytes: imageBytes,
              detections: detections,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("YOLO analysis failed: $e")));
      }

      print("YOLO analysis failed: $e");
    }
  }
}
