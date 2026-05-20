import 'package:flutter/foundation.dart'; // Added for debugPrint
import '../models/detection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // For base64 encoding

class GeminiService {
  static Future<String> detectHazards(Uint8List imageBytes) async {
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
        return response.data['result'].toString();
      } else {
        // Log the actual response to see what Supabase is saying
        debugPrint("Full Supabase Response: ${response.data}");
        return "Error: No result found in response.";
      }
    } catch (e) {
      // <--- Added the missing catch block here
      debugPrint("Edge Function Error: $e");
      return "Error: Failed to connect to analyzer. Please try again later.";
    }
  }
}
