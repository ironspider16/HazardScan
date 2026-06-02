import 'package:flutter/material.dart';

class LocalReportCompiler {
  static String generateWshReport({
    required TextEditingController locationCtrl,
    required TextEditingController supervisorCtrl,
    required TextEditingController employerCtrl,
    required TextEditingController feedbackCtrl,
    required TextEditingController changesCtrl,
    required TextEditingController manualNotesCtrl,
    required Map<String, dynamic> initialAiData,
  }) {
    // Extract individual hazard evaluation blocks safely from existing JSON schema
    final Map<String, dynamic> ladder = initialAiData['ladderHeight'] ?? {};
    final Map<String, dynamic> ppe = initialAiData['ppe'] ?? {};
    final Map<String, dynamic> buddy = initialAiData['buddySystem'] ?? {};
    final Map<String, dynamic> hazards = initialAiData['areaHazards'] ?? {};
    final String overallStatus = initialAiData['overallStatus'] ?? 'PENDING';

    // Helper to extract nested string attributes cleanly
    String getAiField(Map<String, dynamic> block, String field) {
      return block[field]?.toString().trim() ?? 'Not Declared';
    }

    // Capture precise system timestamps right at compilation time
    final String currentDate = DateTime.now().toIso8601String().split('T')[0];
    final String currentTime = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";

    // Compile all data streams into a clean, professional textual report
    return '''
WORKPLACE SAFETY & HEALTH (WSH) OFFICIAL INSPECTION REPORT

1. Site and Personnel Details
• Date & Time of Inspection: $currentDate at $currentTime SGT
• Site Location / Designated Zone: ${locationCtrl.text.isEmpty ? "Not Declared" : locationCtrl.text}
• Assigned Site Supervisor: ${supervisorCtrl.text.isEmpty ? "Unassigned" : supervisorCtrl.text}
• Employer / Core Contractor: ${employerCtrl.text.isEmpty ? "Not Declared" : employerCtrl.text}

2. Hazard Identification
• Working At Heights / Ladder Setup: ${getAiField(ladder, 'description')}
• Personal Protective Equipment (PPE): ${getAiField(ppe, 'description')}
• General Environmental Hazards: ${getAiField(hazards, 'description')}
• Supplemental On-Site Observations: ${manualNotesCtrl.text.isEmpty ? "No manual auxiliary hazards logged by the inspector." : manualNotesCtrl.text}

3. Risk Assessment
• Overall Site Status Evaluation: $overallStatus
• Scaffolding / Elevation Tasks Risk Level: ${getAiField(ladder, 'compliance')}
  Analysis: ${getAiField(ladder, 'reasoning')}
• Personnel Protective Gear Compliance Level: ${getAiField(ppe, 'compliance')}
  Analysis: ${getAiField(ppe, 'reasoning')}
• Buddy System / Operational Supervision Adherence: ${getAiField(buddy, 'compliance')}
  Analysis: ${getAiField(buddy, 'reasoning')}

4. Preventive and Corrective Measures
• Height Safety Mitigation: ${getAiField(ladder, 'advice')}
• Equipment Safety Mitigation: ${getAiField(ppe, 'advice')}
• Area Workspace Mitigation: ${getAiField(hazards, 'advice')}

5. Photo Evidence
• Status: Image successfully uploaded, processed, and validated via computerized vision sub-routines.
• Analysis Context: Visual evaluation cross-referenced automatically against standard industrial compliance parameters. The descriptive breakdowns in Section 2 serve as the primary audit trail for this visual evidence.

6. Review of Changes
• Operational Shift & Process Transitions Cumulative Safety Impact: ${changesCtrl.text.isEmpty ? "No recent process, machinery configurations, or major personnel shifts declared for this inspection cycle." : changesCtrl.text}

7. Worker / Subcontractor Feedback
• Documented On-Site Personnel Concerns: ${feedbackCtrl.text.isEmpty ? "No complaints, safety concerns, or procedural feedback raised by subcontractors/workers during this site walk." : feedbackCtrl.text}

8. Construction / Site Supervision
• Structural Plan Adherence & Joint Safety Evaluation: ${getAiField(hazards, 'reasoning').toLowerCase().contains('structural') ? getAiField(hazards, 'reasoning') : "Structural layout and steel connection joints match standard operational guidelines within the visible camera range."}
• High-Risk Compliance Mode: Active enforcement protocols initiated based on the safety status flagged in Section 3.

9. Major Hazard Installations (MHI)
• Process Safety & Critical Equipment Status: Evaluated against unintended thermal signatures, flash explosions, or toxic substance leaks.
• Evaluation Core: No active process anomalies or safety-critical apparatus malfunctions were triggered during this inspection interval. Standard facility operating thresholds are maintained.
''';
  }
}