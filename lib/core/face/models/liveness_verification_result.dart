class LivenessVerificationResult {
  const LivenessVerificationResult({
    required this.isLive,
    required this.liveScore,
    required this.printScore,
    required this.replayScore,
    required this.durationMs,
    required this.rejectionReason,
  });

  /// Final liveness decision.
  final bool isLive;

  /// Probability that the face is a real/live face.
  final double liveScore;

  /// Probability that the input is a printed-photo spoof.
  final double printScore;

  /// Probability that the input is a replay/screen spoof.
  final double replayScore;

  /// Time spent running MiniFASNet inference.
  final int durationMs;

  /// "none" or "spoof".
  final String rejectionReason;

  /// Combined spoof probability.
  double get spoofScore => printScore + replayScore;

  /// The class with the highest probability.
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
