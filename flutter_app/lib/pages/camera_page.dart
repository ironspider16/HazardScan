import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import '../services/gemini_service.dart';
import 'result_screen.dart';
import 'dart:typed_data';

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
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 600,
              width: 600,
              child: image != null
                  ?
                    // Image selected
                    Image.network(image!.path, fit: BoxFit.cover)
                  :
                    // No image selected
                    const Center(child: Text("No image selected")),
            ),
            const SizedBox(height: 20),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera button
                ElevatedButton(
                  onPressed: () => pickImage(ImageSource.camera),
                  child: const Text("Take a Photo"),
                ),

                // Gallery button
                // ElevatedButton(
                //   onPressed: () => pickImage(ImageSource.gallery),
                //   child: const Text("Gallery"),
                // ),
                ElevatedButton(
                  onPressed: image == null ? null : () => _runAnalysis(context),
                  child: const Text("Analysis Hazard"),
                ),
              ],
            ),
            // const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
