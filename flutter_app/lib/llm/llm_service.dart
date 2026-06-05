import 'package:supabase_flutter/supabase_flutter.dart';

class LlmService {
  static Future<String> generateWeeklyReport({
    required int totalInspections,
    required int missingPPE,
    required int buddySystem,
    required int ladderIssues,
    required int areaHazards,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'weekly-report',
        body: {
          'totalInspections': totalInspections,
          'missingPPE': missingPPE,
          'buddySystem': buddySystem,
          'ladderIssues': ladderIssues,
          'areaHazards': areaHazards,
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      if (response.data is Map && response.data['report'] != null) {
        return response.data['report'].toString();
      }

      if (response.data is Map && response.data['error'] != null) {
        return "Error: ${response.data['error']}";
      }

      return "No report generated. Response: ${response.data}";
    } catch (e) {
      print("Error generating report: $e");
      return "Error generating report: $e";
    }
  }
}
