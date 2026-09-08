class MiniFasLivenessResult {
  const MiniFasLivenessResult({
    required this.printScore,
    required this.liveScore,
    required this.replayScore,
    required this.isLive,
    required this.durationMs,
  });

  final double printScore;
  final double liveScore;
  final double replayScore;
  final bool isLive;
  final int durationMs;

  double get spoofScore => printScore + replayScore;

  String get predictedClass {
    if (liveScore >= printScore && liveScore >= replayScore) {
      return 'live';
    }

    if (printScore >= replayScore) {
      return 'print';
    }

    return 'replay';
  }
}
