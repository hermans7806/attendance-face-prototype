import 'dart:math' as math;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/active_liveness_result.dart';

class ActiveLivenessService {
  ActiveLivenessService({
    this.openThreshold = 0.65,
    this.closedThreshold = 0.30,
    this.smileThreshold = 0.65,
    this.calibrationDuration = const Duration(milliseconds: 500),
    this.requiredStableFrames = 2,
    this.totalTimeout = const Duration(seconds: 6),
  });

  final double openThreshold;
  final double closedThreshold;
  final double smileThreshold;

  final Duration calibrationDuration;
  final int requiredStableFrames;
  final Duration totalTimeout;

  ActiveLivenessPhase _phase = ActiveLivenessPhase.waitingForFace;

  ActiveLivenessChallenge? _challenge;

  ActiveLivenessChallenge? get challenge => _challenge;

  DateTime? _startedAt;
  DateTime? _calibrationStartedAt;

  int _stableFrames = 0;

  ActiveLivenessResult? _result;

  ActiveLivenessPhase get phase => _phase;

  ActiveLivenessResult? get result => _result;

  bool get isComplete =>
      _phase == ActiveLivenessPhase.passed ||
      _phase == ActiveLivenessPhase.failed;

  void start() {
    _challenge = math.Random().nextBool()
        ? ActiveLivenessChallenge.blink
        : ActiveLivenessChallenge.smile;

    _phase = ActiveLivenessPhase.calibrating;

    _startedAt = DateTime.now();
    _calibrationStartedAt = _startedAt;

    _stableFrames = 0;
    _result = null;
  }

  void updateFace(Face face) {
    if (isComplete) {
      return;
    }

    if (_startedAt == null) {
      start();
    }

    final now = DateTime.now();

    // ----------------------------------------------------------
    // Total timeout
    // ----------------------------------------------------------

    if (now.difference(_startedAt!) > totalTimeout) {
      final challengeName = _challenge == ActiveLivenessChallenge.smile
          ? 'Smile'
          : 'Blink';

      _fail('$challengeName verification timed out.');
      return;
    }

    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;
    final smilingProbability = face.smilingProbability;

    if (leftEye == null || rightEye == null) {
      return;
    }

    // Use the average of both eyes.
    //
    // This is more forgiving than requiring both eyes to
    // independently cross the threshold on every frame.

    final eyeOpenProbability = (leftEye + rightEye) / 2.0;

    switch (_phase) {
      case ActiveLivenessPhase.calibrating:
        _handleCalibration(eyeOpenProbability, smilingProbability, now);

      case ActiveLivenessPhase.waitingForOpen:
        _handleWaitingForOpen(eyeOpenProbability);

      case ActiveLivenessPhase.waitingForClosed:
        _handleWaitingForClosed(eyeOpenProbability);

      case ActiveLivenessPhase.waitingForOpenAfterBlink:
        _handleWaitingForOpenAfterBlink(eyeOpenProbability);

      case ActiveLivenessPhase.waitingForSmile:
        _handleWaitingForSmile(smilingProbability);

      case ActiveLivenessPhase.waitingForFace:
      case ActiveLivenessPhase.passed:
      case ActiveLivenessPhase.failed:
        break;
    }
  }

  void _handleCalibration(
    double eyeOpenProbability,
    double? smilingProbability,
    DateTime now,
  ) {
    final elapsed = now.difference(_calibrationStartedAt!);

    if (elapsed < calibrationDuration) {
      return;
    }

    if (_challenge == ActiveLivenessChallenge.smile) {
      _phase = ActiveLivenessPhase.waitingForSmile;
      _stableFrames = 0;
      return;
    }

    // Blink challenge.
    if (eyeOpenProbability >= openThreshold) {
      _phase = ActiveLivenessPhase.waitingForClosed;
      _stableFrames = 0;
    } else {
      _phase = ActiveLivenessPhase.waitingForOpen;
      _stableFrames = 0;
    }
  }

  void _handleWaitingForOpen(double probability) {
    if (probability >= openThreshold) {
      _stableFrames++;

      if (_stableFrames >= requiredStableFrames) {
        _phase = ActiveLivenessPhase.waitingForClosed;
        _stableFrames = 0;
      }
    } else {
      _stableFrames = 0;
    }
  }

  void _handleWaitingForClosed(double probability) {
    if (probability <= closedThreshold) {
      _stableFrames++;

      if (_stableFrames >= requiredStableFrames) {
        _phase = ActiveLivenessPhase.waitingForOpenAfterBlink;

        _stableFrames = 0;
      }
    } else {
      _stableFrames = 0;
    }
  }

  void _handleWaitingForOpenAfterBlink(double probability) {
    if (probability >= openThreshold) {
      _stableFrames++;

      if (_stableFrames >= requiredStableFrames) {
        _pass();
      }
    } else {
      _stableFrames = 0;
    }
  }

  void _handleWaitingForSmile(double? smilingProbability) {
    if (smilingProbability == null) {
      _stableFrames = 0;
      return;
    }

    if (smilingProbability >= smileThreshold) {
      _stableFrames++;

      if (_stableFrames >= requiredStableFrames) {
        _pass();
      }
    } else {
      _stableFrames = 0;
    }
  }

  void _pass() {
    final startedAt = _startedAt ?? DateTime.now();

    _phase = ActiveLivenessPhase.passed;

    _result = ActiveLivenessResult(
      passed: true,
      duration: DateTime.now().difference(startedAt),
      phase: ActiveLivenessPhase.passed,
      challenge: _challenge,
    );
  }

  void _fail(String reason) {
    final startedAt = _startedAt ?? DateTime.now();

    _phase = ActiveLivenessPhase.failed;

    _result = ActiveLivenessResult(
      passed: false,
      duration: DateTime.now().difference(startedAt),
      phase: ActiveLivenessPhase.failed,
      challenge: _challenge,
      reason: reason,
    );
  }

  void dispose() {
    _result = null;
    _startedAt = null;
    _calibrationStartedAt = null;
    _stableFrames = 0;
  }
}
