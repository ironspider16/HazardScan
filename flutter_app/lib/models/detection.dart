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
}
