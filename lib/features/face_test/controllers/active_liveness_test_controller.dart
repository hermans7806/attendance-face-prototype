import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../core/face/liveness/models/active_liveness_result.dart';
import '../../../core/face/liveness/services/active_liveness_service.dart';

class ActiveLivenessTestController extends GetxController {
  ActiveLivenessTestController({ActiveLivenessService? livenessService})
    : _livenessService = livenessService ?? ActiveLivenessService();

  final ActiveLivenessService _livenessService;

  final isInitialized = false.obs;
  final isProcessing = false.obs;

  final phase = ActiveLivenessPhase.waitingForFace.obs;

  final instruction = 'Starting camera...'.obs;

  final detectedFace = false.obs;

  final leftEyeProbability = RxnDouble();
  final rightEyeProbability = RxnDouble();
  final eyeOpenProbability = RxnDouble();
  final smileProbability = RxnDouble();

  final result = Rxn<ActiveLivenessResult>();

  final errorMessage = RxnString();

  CameraController? cameraController;

  late final FaceDetector _faceDetector;

  bool _processingFrame = false;
  DateTime? _lastFrameProcessedAt;

  Timer? _resultTimer;

  int _diagnosticFrame = 0;

  // ---------------------------------------------------------------------------
  // Anti photo-swap / face continuity tracking
  // ---------------------------------------------------------------------------

  Offset? _previousFaceCenter;
  double? _previousFaceWidth;
  double? _previousFaceHeight;
  double? _previousHeadY;
  double? _previousHeadX;

  bool _challengeContinuityTracking = false;
  int _faceLossDuringChallenge = 0;

  // We don't want a perfectly normal small movement to invalidate a blink.
  static const double _maxCenterJump = 35.0;
  static const double _maxFaceSizeRatioChange = 0.22;
  static const double _maxHeadYJump = 12.0;
  static const double _maxHeadXJump = 12.0;

  // More than one suspicious signal makes us much more confident
  // that the image changed rather than the person's face naturally moving.
  int _suspiciousMovementCount = 0;

  // ---------------------------------------------------------------------------

  @override
  void onReady() {
    super.onReady();

    initialize();
  }

  @override
  void onInit() {
    super.onInit();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: false,
        enableContours: false,
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  Future<void> initialize() async {
    if (isInitialized.value) {
      return;
    }

    try {
      isProcessing.value = true;
      errorMessage.value = null;

      final cameras = await availableCameras();

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await controller.initialize();

      cameraController = controller;

      isInitialized.value = true;

      startLiveness();
    } catch (e, stackTrace) {
      errorMessage.value = e.toString();

      debugPrint('Active liveness initialization failed: $e');

      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isProcessing.value = false;
    }
  }

  void startLiveness() {
    _resultTimer?.cancel();

    result.value = null;

    errorMessage.value = null;

    detectedFace.value = false;

    leftEyeProbability.value = null;
    rightEyeProbability.value = null;
    eyeOpenProbability.value = null;
    smileProbability.value = null;

    _diagnosticFrame = 0;

    _resetFaceContinuity();

    _livenessService.start();

    _updateUi();

    final controller = cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isStreamingImages) {
      return;
    }

    controller.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_processingFrame) {
      return;
    }

    // Don't process every camera frame.
    //
    // This keeps ML Kit from consuming unnecessary CPU.
    final now = DateTime.now();

    if (_lastFrameProcessedAt != null &&
        now.difference(_lastFrameProcessedAt!) <
            const Duration(milliseconds: 100)) {
      return;
    }

    _lastFrameProcessedAt = now;

    _processingFrame = true;

    try {
      final inputImage = _convertCameraImage(image);

      if (inputImage == null) {
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      debugPrint('LIVENESS: ML Kit faces=${faces.length}');

      if (faces.isEmpty) {
        detectedFace.value = false;

        _handleFaceLoss();

        instruction.value = 'Position your face inside the frame';

        return;
      }

      if (faces.length > 1) {
        detectedFace.value = false;

        _handleFaceLoss();

        instruction.value = 'Only one face should be visible';

        return;
      }

      final face = faces.first;

      final leftEye = face.leftEyeOpenProbability;
      final rightEye = face.rightEyeOpenProbability;

      final avgEye = (leftEye != null && rightEye != null)
          ? (leftEye + rightEye) / 2.0
          : null;

      final smilingProbability = face.smilingProbability;

      final box = face.boundingBox;

      debugPrint(
        'LIVENESS_FRAME '
        'n=${_diagnosticFrame++} '
        'challenge=${_livenessService.challenge?.name} '
        'left=${leftEye?.toStringAsFixed(3)} '
        'right=${rightEye?.toStringAsFixed(3)} '
        'avg=${avgEye?.toStringAsFixed(3)} '
        'smile=${smilingProbability?.toStringAsFixed(3)} '
        'headY=${face.headEulerAngleY?.toStringAsFixed(1)} '
        'headX=${face.headEulerAngleX?.toStringAsFixed(1)} '
        'headZ=${face.headEulerAngleZ?.toStringAsFixed(1)} '
        'center=${box.center.dx.toStringAsFixed(1)},'
        '${box.center.dy.toStringAsFixed(1)} '
        'size=${box.width.toStringAsFixed(1)}x'
        '${box.height.toStringAsFixed(1)}',
      );

      detectedFace.value = true;

      leftEyeProbability.value = leftEye;
      rightEyeProbability.value = rightEye;
      eyeOpenProbability.value = avgEye;
      smileProbability.value = smilingProbability;

      // Track geometry BEFORE sending the frame to the liveness service.
      _updateFaceContinuity(face);

      // If this blink has already shown strong evidence of a photo swap,
      // don't allow the current frame to complete the blink.
      if (_shouldRejectChallengeBeforeUpdate()) {
        debugPrint(
          'LIVENESS: suspicious challenge detected, '
          'movementCount=$_suspiciousMovementCount, '
          'faceLoss=$_faceLossDuringChallenge',
        );

        _resetLivenessAfterSuspiciousBlink();

        return;
      }

      _livenessService.updateFace(face);

      debugPrint(
        'LIVENESS: '
        'challenge=${_livenessService.challenge?.name}, '
        'phase=${_livenessService.phase}, '
        'avgEye=${eyeOpenProbability.value?.toStringAsFixed(3)}, '
        'smile=${smileProbability.value?.toStringAsFixed(3)}',
      );

      phase.value = _livenessService.phase;

      _updateUi();

      if (_livenessService.isComplete) {
        result.value = _livenessService.result;

        await _stopImageStream();
      }
    } catch (e, stackTrace) {
      debugPrint('Active liveness frame failed: $e');

      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _processingFrame = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Face continuity
  // ---------------------------------------------------------------------------

  void _updateFaceContinuity(Face face) {
    final currentPhase = _livenessService.phase;

    // We start tracking once the user has reached the blink stage.
    final shouldTrack =
        currentPhase == ActiveLivenessPhase.waitingForClosed ||
        currentPhase == ActiveLivenessPhase.waitingForOpenAfterBlink ||
        currentPhase == ActiveLivenessPhase.waitingForSmile;

    if (!shouldTrack) {
      _updatePreviousFaceGeometry(face);
      return;
    }

    final box = face.boundingBox;
    final center = box.center;

    final currentWidth = box.width;
    final currentHeight = box.height;

    final currentHeadY = face.headEulerAngleY;
    final currentHeadX = face.headEulerAngleX;

    if (!_challengeContinuityTracking) {
      _challengeContinuityTracking = true;

      _previousFaceCenter = center;
      _previousFaceWidth = currentWidth;
      _previousFaceHeight = currentHeight;
      _previousHeadY = currentHeadY;
      _previousHeadX = currentHeadX;

      debugPrint(
        'LIVENESS_CONTINUITY: tracking started '
        'center=${center.dx.toStringAsFixed(1)},'
        '${center.dy.toStringAsFixed(1)} '
        'size=${currentWidth.toStringAsFixed(1)}x'
        '${currentHeight.toStringAsFixed(1)}',
      );

      return;
    }

    final previousCenter = _previousFaceCenter;
    final previousWidth = _previousFaceWidth;
    final previousHeight = _previousFaceHeight;
    final previousHeadY = _previousHeadY;
    final previousHeadX = _previousHeadX;

    if (previousCenter != null) {
      final dx = center.dx - previousCenter.dx;
      final dy = center.dy - previousCenter.dy;

      final centerJump = _distance(
        previousCenter.dx,
        previousCenter.dy,
        center.dx,
        center.dy,
      );

      if (centerJump > _maxCenterJump) {
        _suspiciousMovementCount++;

        debugPrint(
          'LIVENESS_CONTINUITY: suspicious center jump '
          'dx=${dx.toStringAsFixed(1)} '
          'dy=${dy.toStringAsFixed(1)} '
          'distance=${centerJump.toStringAsFixed(1)}',
        );
      }
    }

    if (previousWidth != null && previousHeight != null) {
      final widthRatio = _relativeDifference(currentWidth, previousWidth);

      final heightRatio = _relativeDifference(currentHeight, previousHeight);

      if (widthRatio > _maxFaceSizeRatioChange ||
          heightRatio > _maxFaceSizeRatioChange) {
        _suspiciousMovementCount++;

        debugPrint(
          'LIVENESS_CONTINUITY: suspicious face size change '
          'width=${widthRatio.toStringAsFixed(3)} '
          'height=${heightRatio.toStringAsFixed(3)}',
        );
      }
    }

    if (currentHeadY != null && previousHeadY != null) {
      final deltaY = (currentHeadY - previousHeadY).abs();

      if (deltaY > _maxHeadYJump) {
        _suspiciousMovementCount++;

        debugPrint(
          'LIVENESS_CONTINUITY: suspicious headY jump '
          '${deltaY.toStringAsFixed(1)} degrees',
        );
      }
    }

    if (currentHeadX != null && previousHeadX != null) {
      final deltaX = (currentHeadX - previousHeadX).abs();

      if (deltaX > _maxHeadXJump) {
        _suspiciousMovementCount++;

        debugPrint(
          'LIVENESS_CONTINUITY: suspicious headX jump '
          '${deltaX.toStringAsFixed(1)} degrees',
        );
      }
    }

    _updatePreviousFaceGeometry(face);
  }

  void _updatePreviousFaceGeometry(Face face) {
    final box = face.boundingBox;

    _previousFaceCenter = box.center;
    _previousFaceWidth = box.width;
    _previousFaceHeight = box.height;
    _previousHeadY = face.headEulerAngleY;
    _previousHeadX = face.headEulerAngleX;
  }

  void _handleFaceLoss() {
    if (!_challengeContinuityTracking) {
      return;
    }

    _faceLossDuringChallenge++;

    debugPrint(
      'LIVENESS_CONTINUITY: face lost during challenge '
      'challenge=${_livenessService.challenge?.name} '
      'count=$_faceLossDuringChallenge',
    );
  }

  bool _shouldRejectChallengeBeforeUpdate() {
    final currentPhase = _livenessService.phase;

    final criticalPhase =
        currentPhase == ActiveLivenessPhase.waitingForOpenAfterBlink ||
        currentPhase == ActiveLivenessPhase.waitingForSmile;

    if (!criticalPhase) {
      return false;
    }

    if (_suspiciousMovementCount >= 2) {
      return true;
    }

    if (_faceLossDuringChallenge >= 2) {
      return true;
    }

    return false;
  }

  void _resetLivenessAfterSuspiciousBlink() {
    debugPrint('LIVENESS: rejecting suspicious blink and restarting challenge');

    _resetFaceContinuity();

    _livenessService.start();

    debugPrint(
      'LIVENESS: START '
      'challenge=${_livenessService.challenge?.name} '
      'phase=${_livenessService.phase.name}',
    );

    phase.value = _livenessService.phase;

    _updateUi();
  }

  void _resetFaceContinuity() {
    _previousFaceCenter = null;
    _previousFaceWidth = null;
    _previousFaceHeight = null;
    _previousHeadY = null;
    _previousHeadX = null;

    _challengeContinuityTracking = false;
    _faceLossDuringChallenge = 0;
    _suspiciousMovementCount = 0;
  }

  double _distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;

    return math.sqrt(dx * dx + dy * dy);
  }

  double _relativeDifference(double current, double previous) {
    if (previous == 0) {
      return 0;
    }

    return ((current - previous).abs() / previous);
  }

  // ---------------------------------------------------------------------------

  void _updateUi() {
    switch (_livenessService.phase) {
      case ActiveLivenessPhase.waitingForFace:
        instruction.value = 'Position your face inside the frame';

      case ActiveLivenessPhase.calibrating:
        instruction.value = 'Look at the camera...';

      case ActiveLivenessPhase.waitingForOpen:
        instruction.value = 'Open your eyes';

      case ActiveLivenessPhase.waitingForClosed:
        instruction.value = 'Please blink once';

      case ActiveLivenessPhase.waitingForOpenAfterBlink:
        instruction.value = 'Open your eyes';

      case ActiveLivenessPhase.waitingForSmile:
        instruction.value = 'Please smile';

      case ActiveLivenessPhase.passed:
        instruction.value = 'Liveness verified';

      case ActiveLivenessPhase.failed:
        instruction.value =
            _livenessService.result?.reason ?? 'Liveness verification failed';
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    if (image.planes.isEmpty) {
      return null;
    }

    final camera = cameraController;

    if (camera == null) {
      return null;
    }

    final cameraDescription = camera.description;

    final rotation = _rotationFromCamera(cameraDescription.sensorOrientation);

    final bytes = image.planes.first.bytes;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.nv21,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    debugPrint(
      'LIVENESS: camera sensorOrientation='
      '${cameraDescription.sensorOrientation}, '
      'image=${image.width}x${image.height}, '
      'rotation=$rotation',
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  InputImageRotation _rotationFromCamera(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;

      case 180:
        return InputImageRotation.rotation180deg;

      case 270:
        return InputImageRotation.rotation270deg;

      case 0:
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _stopImageStream() async {
    final controller = cameraController;

    if (controller == null) {
      return;
    }

    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
  }

  Future<void> retry() async {
    await _stopImageStream();

    startLiveness();
  }

  @override
  void onClose() {
    _resultTimer?.cancel();

    _stopImageStream();

    cameraController?.dispose();

    _faceDetector.close();

    _livenessService.dispose();

    super.onClose();
  }
}
