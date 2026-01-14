// lib/models/swp.dart

enum SwpCategory { wah, ln2, confined }

class SwpTemplate {
  final String id;
  final SwpCategory category;
  final String title;
  final List<String> checklist;

  const SwpTemplate({
    required this.id,
    required this.category,
    required this.title,
    required this.checklist,
  });
}

class SwpRecord {
  final String templateId;
  final String templateTitle;
  final SwpCategory category;
  final DateTime createdAt;

  // acknowledgement details
  final String name;
  final String designation;
  final String department;

  // WAH-specific
  final bool? workingAbove3m;
  final String? ptwNumber;

  // checklist result
  final List<bool> checks;

  // Attachments (paths on device)
  final List<String> attachments;

  // Optional notes
  final String notes;

  SwpRecord({
    required this.templateId,
    required this.templateTitle,
    required this.category,
    required this.createdAt,
    required this.name,
    required this.designation,
    required this.department,
    required this.checks,
    required this.attachments,
    required this.notes,
    this.workingAbove3m,
    this.ptwNumber,
  });
}
  