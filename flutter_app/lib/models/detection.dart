class Detection {
  final double left;
  final double top;
  final double right;
  final double bottom;
  final int classId;
  final double confidence;
  final String label;

  Detection({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.classId,
    required this.confidence,
    this.label= "", //optional parameter
  });
}
