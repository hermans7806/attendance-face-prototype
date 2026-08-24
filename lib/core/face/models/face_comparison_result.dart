class FaceComparisonResult {
  const FaceComparisonResult({required this.distance, required this.threshold});

  final double distance;
  final double threshold;

  bool get isMatch => distance < threshold;
}
