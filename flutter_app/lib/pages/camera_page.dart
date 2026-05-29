import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import '../services/gemini_service.dart';
import 'result_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kkhazardscan/models/detection.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  // Image File
  XFile? image;

  // Image Picker
  final picker = ImagePicker();

  // Pick Image Method
  Future<void> pickImage(ImageSource source) async {
    //Pick from camera or gallery
    final pickedFile = await picker.pickImage(source: source);

    // Update selected image
    if (pickedFile != null) {
      setState(() {
        image = pickedFile;
      });
    }
  }

  //AI Analysis
  Future<void> _runAnalysis(BuildContext context) async {
    if (image == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final imagePath = image!.path;
      final imageBytes = await image!.readAsBytes();

      final detections = await GeminiService.detectHazards(imageBytes);

      if (context.mounted) Navigator.pop(context);

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
        ).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
      }
    }
  }

  // YOLO Spreader Detection
  Future<void> uploadImage(BuildContext context, String imagePath) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final imageBytes = await image!.readAsBytes();

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
          filename: image!.name,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Taking"),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 0, 0, 0),
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 1000;

          final imageSize = isMobile
              ? constraints.maxWidth * 0.9
              : constraints.maxWidth * 0.6;

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: imageSize,
                      width: imageSize,
                      child: image != null
                          ? Image.network(image!.path, fit: BoxFit.cover)
                          : const Center(child: Text("No image selected")),
                    ),

                    const SizedBox(height: 20),

                    isMobile
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      pickImage(ImageSource.camera),
                                  child: const Text("Take a Photo"),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: image == null
                                      ? null
                                      // : () => _runAnalysis(context),
                                      : () => uploadImage(context, image!.path),
                                  child: const Text("Analysis Hazard"),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () => pickImage(ImageSource.camera),
                                child: const Text("Take a Photo"),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: image == null
                                    ? null
                                    // : () => _runAnalysis(context),
                                    : () => uploadImage(context, image!.path),
                                child: const Text("Analysis Hazard"),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
