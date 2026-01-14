import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  late List<CameraDescription> cameras;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras(); // Laptop webcam or phone camera

    controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller!.initialize();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,

      // ------------------ APP BAR WITH WHITE BACK BUTTON ------------------
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white, // back arrow colour
        ),
      ),

      // ------------------ CAMERA PREVIEW ------------------
      body: Stack(  
        children: [
          CameraPreview(controller!),

          // Capture button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () async {
                  final file = await controller!.takePicture();
                  Navigator.pop(context, file.path); // Return image path
                },
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.black,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
