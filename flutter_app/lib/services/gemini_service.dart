import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:kkhazardscan/pages/camera_page.dart';

class GeminiService {
  static Future<String> detectHazards(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await Supabase.instance.client.functions.invoke(
        'analyze-hazard',
        body: {'imageBase64': base64Image},
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