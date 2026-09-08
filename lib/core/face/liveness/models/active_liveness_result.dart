enum ActiveLivenessChallenge { blink, smile }

enum ActiveLivenessPhase {
  waitingForFace,
  calibrating,
  waitingForOpen,
  waitingForClosed,
  waitingForOpenAfterBlink,
  waitingForSmile,
  passed,
  failed,
}

class ActiveLivenessResult {
  const ActiveLivenessResult({
    required this.passed,
    required this.duration,
    required this.phase,
    this.challenge,
    this.reason,
  });

  final bool passed;
  final Duration duration;
  final ActiveLivenessPhase phase;
  final ActiveLivenessChallenge? challenge;
  final String? reason;
}
