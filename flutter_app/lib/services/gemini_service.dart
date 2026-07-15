import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

/// Typed result from the hazard analysis edge function.
/// Always check [isError] before using [jsonPayload].
class HazardAnalysisResult {
  final String jsonPayload;     // Full raw JSON — pass this to your existing parser
  final bool isError;           // True if edge function returned a diagnostic error
  final String? errorType;      // e.g. "EXHAUSTION_ERROR", "SDK_ERROR", "SETUP_ERROR"
  final String? errorTitle;     // Human-readable title for the error dialog
  final String? errorDetail;    // Full detail string for the error dialog
  final String? systemNotice;   // Non-null if a fallback model was used
  final int? keySlot;           // Which API key index was used (0-based)
  final String? modelUsed;      // Which Gemini model actually responded

  const HazardAnalysisResult({
    required this.jsonPayload,
    required this.isError,
    this.errorType,
    this.errorTitle,
    this.errorDetail,
    this.systemNotice,
    this.keySlot,
    this.modelUsed,
  });
}

class GeminiService {
  static Future<HazardAnalysisResult> detectHazards(
    List<Uint8List> imagesBytes, [
    String userContext = "",
    Map<String, dynamic>? previousAnalysis, 
  ]) async {
    try {
      final base64Images = imagesBytes.map((bytes) => base64Encode(bytes)).toList();

      final response = await Supabase.instance.client.functions.invoke(
        'analyze-hazard',
        body: {
          'imagesBase64': base64Images,
          'userContext': userContext,
          'previousAnalysis': previousAnalysis, 
        },
      );

      if (response.data == null) {
        return const HazardAnalysisResult(
          jsonPayload: "",
          isError: true,
          errorType: "NULL_RESPONSE",
          errorTitle: "No Response",
          errorDetail: "The edge function returned an empty response. Check Supabase logs.",
        );
      }

      final rawJson = jsonEncode(response.data);
      debugPrint("=== RAW AI RESPONSE START ===");
      debugPrint(rawJson);
      debugPrint("=== RAW AI RESPONSE END ===");

      final decoded = response.data as Map<String, dynamic>;

      // Check for diagnostic error flag injected by the edge function
      final errorType = decoded['errorType'] as String?;
      final isError = errorType != null && errorType.isNotEmpty;

      return HazardAnalysisResult(
        jsonPayload: rawJson,
        isError: isError,
        errorType: errorType,
        errorTitle: isError
            ? (decoded['ladderHeight']?['description'] as String?)
                ?.replaceFirst('Diagnostic: ', '')
            : null,
        errorDetail: isError
            ? ((decoded['ladderHeight']?['reasoning'] as String?) ?? '')
            : null,
        systemNotice: decoded['systemNotice'] as String?,
        keySlot: decoded['keySlot'] as int?,
        modelUsed: decoded['modelUsed'] as String?,
      );
    } catch (e) {
      debugPrint("GeminiService error: $e");
      return HazardAnalysisResult(
        jsonPayload: "",
        isError: true,
        errorType: "CONNECTION_ERROR",
        errorTitle: "Connection Failed",
        errorDetail: e.toString(),
      );
    }
  }
}