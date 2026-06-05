import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportStatisticsService {
  static final supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> getRiskScores() async {
    final response = await supabase.from('safety_reports').select('''
      *,
      swp_templates!inner(id, category, title),
      WAH_safetyVariables(*)
    ''');

    final reports = List<Map<String, dynamic>>.from(response);

    final scores = calculateRiskScores(reports);

    return {'totalReports': reports.length, 'scores': scores};
  }

  static Map<String, int> calculateRiskScores(
    List<Map<String, dynamic>> reports,
  ) {
    Map<String, int> scores = {
      'Ladder Height': 0,
      'PPE': 0,
      'Buddy System': 0,
      'Area Hazards': 0,
    };

    int getScore(String? compliance) {
      switch (compliance?.toUpperCase()) {
        case 'SAFE':
          return 0;
        case 'COMPLIANT':
          return 1;
        case 'PARTIALLY COMPLIANT':
          return 2;
        case 'DANGEROUS':
          return 4;
        default:
          return 0;
      }
    }

    int extractScore(dynamic data) {
      if (data == null) return 0;

      final Map<String, dynamic> parsed = data is String
          ? Map<String, dynamic>.from(jsonDecode(data))
          : Map<String, dynamic>.from(data);

      return getScore(parsed['compliance'] as String?);
    }

    for (final report in reports) {
      final rawVars = report['WAH_safetyVariables'];

      final vars = rawVars is List && rawVars.isNotEmpty
          ? rawVars.first
          : rawVars;

      if (vars != null) {
        scores['Ladder Height'] =
            scores['Ladder Height']! + extractScore(vars['ladderheight']);

        scores['PPE'] = scores['PPE']! + extractScore(vars['ppe']);

        scores['Buddy System'] =
            scores['Buddy System']! + extractScore(vars['buddySystem']);

        scores['Area Hazards'] =
            scores['Area Hazards']! + extractScore(vars['areaHazards']);
      }
    }

    return scores;
  }
}
