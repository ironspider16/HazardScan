class Detection {
  final String label;
  final double confidence;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final int? classId;

  Detection({
    required this.label,
    required this.confidence,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.classId,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      label: json['label'] ?? '',

      confidence: (json['confidence'] ?? 0).toDouble(),

      left: (json['x1'] ?? 0).toDouble(),

      top: (json['y1'] ?? 0).toDouble(),

      right: (json['x2'] ?? 0).toDouble(),

      bottom: (json['y2'] ?? 0).toDouble(),
    );
  }
}
