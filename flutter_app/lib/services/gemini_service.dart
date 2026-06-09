import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class GeminiService {
  /// Sends an array of compressed multi-angle image data along with an optional 
  /// on-site environmental context string down to the hosted serverless analyzer endpoint.
  /// [userContext] is optional. If left out, it defaults to an empty string ("").
  static Future<String> detectHazards(List<Uint8List> imagesBytes, [String userContext = ""]) async {
    try {
      // 1. Map over all images in the list and encode each to base64
      final base64Images = imagesBytes.map((bytes) => base64Encode(bytes)).toList();

      // 2. Invoke the edge function with the array payload matching the backend structure
      final response = await Supabase.instance.client.functions.invoke(
        'analyze-hazard',
        body: {
          'imagesBase64': base64Images,
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