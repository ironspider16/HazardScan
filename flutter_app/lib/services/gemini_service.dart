import 'package:flutter/foundation.dart'; // Added for debugPrint
import '../models/detection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // For base64 encoding

class GeminiService {
  static Future<List<Detection>> detectHazards(Uint8List imageBytes) async {
    try {
      // Convert image to base64 for the server
      // final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Call your new Supabase Edge Function
      final response = await Supabase.instance.client.functions.invoke(
        'analyze-hazard',
        body: {'imageBase64': base64Image},
      );

      // Safely check if 'result' exists
      if (response.data != null && response.data['result'] != null) {
        final aiText = response.data['result']
            .toString(); // Use .toString() instead of 'as String'
        return _parseGeminiResponse(aiText);
      } else {
        // Log the actual response to see what Supabase is saying
        debugPrint("Full Supabase Response: ${response.data}");
        return [];
      }
    } catch (e) {
      // <--- Added the missing catch block here
      debugPrint("Edge Function Error: $e");
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
        ),
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
