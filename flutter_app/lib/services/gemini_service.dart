<<<<<<< HEAD
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
=======
import 'dart:io';
import 'package:flutter/foundation.dart'; // Added for debugPrint
>>>>>>> Gemini_API_testing_backend
import '../models/detection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // For base64 encoding

class GeminiService {
<<<<<<< HEAD
  // Note: For production, consider using environment variables for the API Key
  static const String _apiKey = 'AIzaSyA27MmHyBP4u_u8oY0dxa46LWS5j0jRJP0';

  static Future<List<Detection>> detectHazards(Uint8List imageBytes) async {
=======
  static Future<List<Detection>> detectHazards(String imagePath) async {
>>>>>>> Gemini_API_testing_backend
    try {
      // Convert image to base64 for the server
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Call your new Supabase Edge Function
      final response = await Supabase.instance.client.functions.invoke(
        'analyze-hazard',
        body: {'imageBase64': base64Image},
      );

<<<<<<< HEAD
      // final imageBytes = await File(imagePath).readAsBytes();

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
        "REASON: [Detailed explanation of what you see]",
      );

      final content = [
        Content.multi([prompt, DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await model.generateContent(content);
      final text = response.text ?? "";
      print("Gemini Analysis Raw: $text");

      return _parseGeminiResponse(text);
    } catch (e) {
      print("Gemini Error: $e");
      return [];
=======
      // Safely check if 'result' exists
      if (response.data != null && response.data['result'] != null) {
        final aiText = response.data['result'].toString(); // Use .toString() instead of 'as String'
        return _parseGeminiResponse(aiText);
      } else {
        // Log the actual response to see what Supabase is saying
        debugPrint("Full Supabase Response: ${response.data}");
        return []; 
      }
    } catch (e) { // <--- Added the missing catch block here
      debugPrint("Edge Function Error: $e");
      return []; 
>>>>>>> Gemini_API_testing_backend
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
<<<<<<< HEAD
          top: 0.0,
          right: 1.0,
          bottom: 1.0,
          classId: _mapStatusToId(status),
          confidence: 1.0,
          label: "[$objectName] $status: $reason", // Now 'label' is recognized!
        ),
=======
          top: 0.0, 
          right: 1.0, 
          bottom: 1.0, 
          classId: _mapStatusToId(status),
          confidence: 1.0,
          label: "[$objectName] $status: $reason", // Now 'label' is recognized!
        )
>>>>>>> Gemini_API_testing_backend
      ];
    } catch (e) {
      debugPrint("Parsing Error: $e");
      return [];
    }
  }

  static int _mapStatusToId(String status) {
    switch (status.toUpperCase()) {
      case 'LOCKED':
        return 2;
      case 'UNLOCKED':
        return 4;
      case 'HAZARD':
        return 0;
      default:
        return 1; // Default to 'ladder' or 'not applicable'
    }
  }
}
