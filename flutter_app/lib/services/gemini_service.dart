import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/detection.dart';

class GeminiService {
  // Note: For production, consider using environment variables for the API Key
  static const String _apiKey = 'AIzaSyCwxc_KRyLrA2KzplT_XBGuqTjldw9iHas';

  static Future<List<Detection>> detectHazards(String imagePath) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview', // Using the stable flash model
        apiKey: _apiKey,
      );

      final imageBytes = await File(imagePath).readAsBytes();

      // IMPROVED PROMPT:
      // We explicitly tell it to be descriptive and avoid generic excuses.
      final prompt = TextPart(
          "Analyze this image for safety hazards. "
          "If the object is a ladder, inspect the spreader bar/hinge, steps, and stability. "
          "If the object is NOT a ladder, identify it clearly. "
          "Provide a specific reason for your status assessment based on visual evidence. "
          "Avoid generic responses like 'take a closer photo' unless the image is completely unrecognizable.\n\n"
          "Return ONLY this format:\n"
          "OBJECT: [Name of object]\n"
          "STATUS: [NOT_APPLICABLE/LOCKED/UNLOCKED/HAZARD]\n"
          "REASON: [Detailed explanation of what you see]"
      );

      final content = [
        Content.multi([
          prompt,
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final text = response.text ?? "";
      print("Gemini Analysis Raw: $text");

      return _parseGeminiResponse(text);
    } catch (e) {
      print("Gemini Error: $e");
      return [];
    }
  }

  /// Parses the "OBJECT/STATUS/REASON" text into a Detection object
  static List<Detection> _parseGeminiResponse(String text) {
    try {
      // Simple parsing logic using RegEx or String splitting
      final objectMatch = RegExp(r"OBJECT:\s*(.*)").firstMatch(text);
      final statusMatch = RegExp(r"STATUS:\s*(.*)").firstMatch(text);
      final reasonMatch = RegExp(r"REASON:\s*(.*)").firstMatch(text);

      final objectName = objectMatch?.group(1)?.trim() ?? "Unknown";
      final status = statusMatch?.group(1)?.trim() ?? "UNKNOWN";
      final reason = reasonMatch?.group(1)?.trim() ?? "No reason provided.";

      // We create one 'Detection' that covers the whole image (0,0 to 1,1)
      // and put the Object + Reason into the label so the UI can show it.
      return [
  Detection(
    left: 0.0, // Set to 0.0 to cover full screen if no specific box
    top: 0.0, 
    right: 1.0, 
    bottom: 1.0, 
    classId: _mapStatusToId(status),
    confidence: 1.0,
    label: "[$objectName] $status: $reason", // Now 'label' is recognized!
  )
];
    } catch (e) {
      print("Parsing Error: $e");
      return [];
    }
  }

  static int _mapStatusToId(String status) {
    switch (status.toUpperCase()) {
      case 'LOCKED': return 2;
      case 'UNLOCKED': return 4;
      case 'HAZARD': return 0;
      default: return 1; // Default to 'ladder' or 'not applicable'
    }
  }
}