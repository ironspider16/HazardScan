import 'dart:io';
import 'package:flutter/material.dart';

class ImageConfirmScreen extends StatelessWidget {
  final String imagePath;

  const ImageConfirmScreen({
    super.key,
    required this.imagePath,
  });

  Future<void> _sendToBackend(BuildContext context) async {
    // TODO: Replace this with your real Python backend API call.
    // For now we just fake a delay.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      Navigator.pop(context); // close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image sent to LLM')),
      );

      // Return "true" to caller = confirmed & sent
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Image"),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Preview of the captured image
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Buttons: Reject / Confirm
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                // Reject / Retake
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // Return "false" = rejected
                      Navigator.pop(context, false);
                    },
                    child: const Text(
                      "Retake",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm / Send
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _sendToBackend(context),
                    child: const Text(
                      "Send",
                      style: TextStyle(fontSize: 16),
                    ),
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
