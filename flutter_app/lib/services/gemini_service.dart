import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';

class GeminiService {
  /// Sends the compressed image data along with an optional on-site environmental 
  /// context string down to the hosted serverless analyzer endpoint.
  /// [userContext] is optional. If left out, it defaults to an empty string ("").
  static Future<String> detectHazards(Uint8List imageBytes, [String userContext = ""]) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await Supabase.instance.client.functions.invoke(
        'analyze-hazard',
        body: {
          'imageBase64': base64Image,
          'userContext': userContext,
        },
      );

      if (response.data != null) {
        final rawResult = jsonEncode(response.data);
        // --- DIAGNOSTIC LOG: Remove this block once parsing is confirmed working ---
        debugPrint("=== RAW AI RESPONSE START ===");
        debugPrint(rawResult);
        debugPrint("=== RAW AI RESPONSE END ===");
        // --------------------------------------------------------------------------

        return rawResult;
      } else {
        debugPrint("Full Supabase Response: ${response.data}");
        return "Error: No result found in response.";
      }
    } catch (e) {
      debugPrint("Edge Function Error: $e");
      return "Error: Failed to connect to analyzer. Please try again later.";
    }
  }
}