import "package:flutter/material.dart";
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:kkhazardscan/models/detection.dart';

class YoloService {
  Future<List<Detection>> yoloDetect(
    BuildContext context,
    Uint8List imageBytes,
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

      return detections;
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("YOLO analysis failed: $e")));
      }

      print("YOLO analysis failed: $e");
      return [];
    }
  }
}
