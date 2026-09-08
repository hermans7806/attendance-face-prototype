import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:face_auth_engine/face_auth_engine.dart' as face_auth;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../models/liveness_verification_result.dart';
import '../../services/liveness_service.dart';

class MiniFasLivenessService implements LivenessService {
  MiniFasLivenessService({
    required this.faceDetector,
    required this.imageProvider,
    this.threshold = 0.50,
    this.cpuThreads = 2,
  });

  final face_auth.FaceDetectorProvider faceDetector;
  final face_auth.FaceImageProvider imageProvider;

  final double threshold;
  final int cpuThreads;

  Interpreter? _interpreter;

  /// Creates the TFLite interpreter and performs one warm-up inference.
  Future<void> initialize() async {
    if (_interpreter != null) {
      return;
    }

    final options = InterpreterOptions()..threads = cpuThreads;

    final interpreter = await Interpreter.fromAsset(
      'packages/minifasnet/assets/silentface.tflite',
      options: options,
    );

    final inputShape = interpreter.getInputTensor(0).shape;
    final outputShape = interpreter.getOutputTensor(0).shape;

    debugPrint('MiniFASNet input shape: $inputShape');
    debugPrint('MiniFASNet output shape: $outputShape');

    if (!listEquals(inputShape, const [1, 3, 80, 80])) {
      interpreter.close();
      throw StateError('Unexpected MiniFASNet input shape: $inputShape');
    }

    if (!listEquals(outputShape, const [1, 3])) {
      interpreter.close();
      throw StateError('Unexpected MiniFASNet output shape: $outputShape');
    }

    _interpreter = interpreter;

    // Warm up once so the first actual test isn't measuring model startup.
    final dummyInput = List.generate(
      1,
      (_) => List.generate(
        3,
        (_) => List.generate(80, (_) => List<double>.filled(80, 0.0)),
      ),
    );

    final dummyOutput = [List<double>.filled(3, 0.0)];

    _interpreter!.run(dummyInput, dummyOutput);

    debugPrint(
      'MiniFAS input type: '
      '${interpreter.getInputTensor(0).type}',
    );

    debugPrint(
      'MiniFAS output type: '
      '${interpreter.getOutputTensor(0).type}',
    );

    debugPrint('MiniFASNet warm-up complete.');
  }

  @override
  Future<LivenessVerificationResult> checkLiveness(File imageFile) async {
    final interpreter = _interpreter;

    if (interpreter == null) {
      await initialize();
    }

    final engine = _interpreter!;

    final stopwatch = Stopwatch()..start();

    // ------------------------------------------------------------
    // 1. Detect exactly one face.
    // ------------------------------------------------------------
    final detector = faceDetector;
    final imageProvider = this.imageProvider;

    final detection = await detector.detectFace(imageFile);
    final fullImage = await imageProvider.loadImage(imageFile);

    // ----------------------------------------------------------
    // 2. Expand the detected face box by ~2.7x.
    //
    // MiniFASNet was trained with a 2.7x face crop rather than
    // the tight ML Kit bounding box.
    // ----------------------------------------------------------
    final cropRect = _expandedCrop(
      detection.boundingBox,
      fullImage.width,
      fullImage.height,
      scale: 2.7,
    );

    final faceCrop = await imageProvider.crop(
      fullImage,
      cropRect.left,
      cropRect.top,
      cropRect.width,
      cropRect.height,
    );

    debugPrint(
      'MiniFASNet crop: '
      'x=${cropRect.left}, '
      'y=${cropRect.top}, '
      'w=${cropRect.width}, '
      'h=${cropRect.height}',
    );

    debugPrint(
      'Source image: '
      '${fullImage.width}x${fullImage.height}',
    );

    debugPrint(
      'Face box: '
      '${detection.boundingBox}',
    );

    await _saveDebugCrop(faceCrop);

    // ----------------------------------------------------------
    // 3. Resize to 80x80.
    // ----------------------------------------------------------
    final resized = await imageProvider.resize(faceCrop, 80, 80);

    //await _saveDebugInputImage(resized);

    // ----------------------------------------------------------
    // 4. RGB -> BGR, normalize /255, convert HWC -> NCHW.
    // ----------------------------------------------------------
    // ------------------------------------------------------------
    // Build both variants from the EXACT SAME 80x80 image.
    // This is a diagnostic only.
    // ------------------------------------------------------------
    final bgrInput = _buildInput(resized, bgr: true);

    final rgbInput = _buildInput(resized, bgr: false);

    // ------------------------------------------------------------
    // Inspect BGR tensor.
    // ------------------------------------------------------------
    _logTensorStats('BGR', bgrInput);

    // ------------------------------------------------------------
    // Inspect RGB tensor.
    // ------------------------------------------------------------
    _logTensorStats('RGB', rgbInput);

    // ------------------------------------------------------------
    // Run BGR inference.
    // ------------------------------------------------------------
    final bgrOutput = [List<double>.filled(3, 0.0)];

    engine.run(bgrInput, bgrOutput);

    debugPrint('MiniFAS BGR raw output: ${bgrOutput.first}');

    final bgrProbabilities = _normalizeOutput(bgrOutput.first);

    debugPrint('MiniFAS BGR probabilities: $bgrProbabilities');

    // ------------------------------------------------------------
    // Run RGB inference.
    // ------------------------------------------------------------
    final rgbOutput = [List<double>.filled(3, 0.0)];

    engine.run(rgbInput, rgbOutput);

    debugPrint('MiniFAS RGB raw output: ${rgbOutput.first}');

    final rgbProbabilities = _normalizeOutput(rgbOutput.first);

    debugPrint('MiniFAS RGB probabilities: $rgbProbabilities');

    final printScore = bgrProbabilities[0];
    final liveScore = bgrProbabilities[1];
    final replayScore = bgrProbabilities[2];

    final isLive =
        liveScore >= threshold &&
        liveScore >= printScore &&
        liveScore >= replayScore;

    stopwatch.stop();

    return LivenessVerificationResult(
      isLive: isLive,
      liveScore: liveScore,
      printScore: printScore,
      replayScore: replayScore,
      durationMs: stopwatch.elapsedMilliseconds,
      rejectionReason: isLive ? 'none' : 'spoof',
    );

    // debugPrint('MiniFAS raw output: ${output.first}');
    //
    // final probabilities = _normalizeOutput(output.first);

    // Class mapping from the model:
    //
    // 0 = print spoof
    // 1 = live
    // 2 = replay spoof
    // final printScore = probabilities[0];
    // final liveScore = probabilities[1];
    // final replayScore = probabilities[2];

    // final isLive =
    //     liveScore >= threshold &&
    //     liveScore >= printScore &&
    //     liveScore >= replayScore;

    // stopwatch.stop();
    //
    // debugPrint(
    //   'MiniFASNet: '
    //   'print=${printScore.toStringAsFixed(4)}, '
    //   'live=${liveScore.toStringAsFixed(4)}, '
    //   'replay=${replayScore.toStringAsFixed(4)}, '
    //   'isLive=$isLive, '
    //   'duration=${stopwatch.elapsedMilliseconds}ms',
    // );
    //
    // return LivenessVerificationResult(
    //   isLive: isLive,
    //   liveScore: liveScore,
    //   printScore: printScore,
    //   replayScore: replayScore,
    //   durationMs: stopwatch.elapsedMilliseconds,
    //   rejectionReason: isLive ? 'none' : 'spoof',
    // );
  }

  /// Returns the 2.7x face crop as integer coordinates.
  _CropRect _expandedCrop(
    Rect boundingBox,
    int imageWidth,
    int imageHeight, {
    required double scale,
  }) {
    final x = boundingBox.left;
    final y = boundingBox.top;
    final boxWidth = boundingBox.width;
    final boxHeight = boundingBox.height;

    // This is the same scale limiting logic used by the
    // original Silent-Face-Anti-Spoofing CropImage implementation.
    final actualScale = math.min(
      (imageHeight - 1) / boxHeight,
      math.min((imageWidth - 1) / boxWidth, scale),
    );

    final newWidth = boxWidth * actualScale;
    final newHeight = boxHeight * actualScale;

    final centerX = boxWidth / 2 + x;
    final centerY = boxHeight / 2 + y;

    var left = centerX - newWidth / 2;
    var top = centerY - newHeight / 2;
    var right = centerX + newWidth / 2;
    var bottom = centerY + newHeight / 2;

    // Shift the complete crop back inside the image,
    // preserving its dimensions where possible.
    if (left < 0) {
      right -= left;
      left = 0;
    }

    if (top < 0) {
      bottom -= top;
      top = 0;
    }

    if (right > imageWidth - 1) {
      left -= right - imageWidth + 1;
      right = imageWidth - 1;
    }

    if (bottom > imageHeight - 1) {
      top -= bottom - imageHeight + 1;
      bottom = imageHeight - 1;
    }

    return _CropRect(
      left: left.round(),
      top: top.round(),
      width: (right - left + 1).round(),
      height: (bottom - top + 1).round(),
    );
  }

  /// Creates [1, 3, 80, 80] NCHW input.
  ///
  /// Source buffer is RGB.
  /// Model expects BGR normalized to [0, 1].
  List<List<List<List<double>>>> _buildInput(
    face_auth.FaceImageBuffer image, {
    required bool bgr,
  }) {
    final input = List.generate(
      1,
      (_) => List.generate(
        3,
        (_) => List.generate(80, (_) => List<double>.filled(80, 0.0)),
      ),
    );

    for (var y = 0; y < 80; y++) {
      for (var x = 0; x < 80; x++) {
        final r = image.getR(x, y) / 255.0;
        final g = image.getG(x, y) / 255.0;
        final b = image.getB(x, y) / 255.0;

        if (bgr) {
          input[0][0][y][x] = b;
          input[0][1][y][x] = g;
          input[0][2][y][x] = r;
        } else {
          input[0][0][y][x] = r;
          input[0][1][y][x] = g;
          input[0][2][y][x] = b;
        }
      }
    }

    return input;
  }

  /// The documented LiteRT model already returns softmax probabilities.
  ///
  /// This also handles an equivalent conversion that returns logits:
  /// if the values don't look like probabilities, apply softmax.
  List<double> _normalizeOutput(List<double> raw) {
    final looksLikeProbabilities =
        raw.every((value) => value >= 0.0 && value <= 1.0) &&
        (raw.fold<double>(0, (sum, value) => sum + value) - 1.0).abs() < 0.01;

    if (looksLikeProbabilities) {
      return raw;
    }

    final maxValue = raw.reduce(math.max);

    final exponentials = raw
        .map((value) => math.exp(value - maxValue))
        .toList();

    final sum = exponentials.fold<double>(
      0.0,
      (previous, value) => previous + value,
    );

    return exponentials.map((value) => value / sum).toList();
  }

  Future<File> _saveDebugCrop(face_auth.FaceImageBuffer buffer) async {
    final image = img.Image(width: buffer.width, height: buffer.height);

    for (var y = 0; y < buffer.height; y++) {
      for (var x = 0; x < buffer.width; x++) {
        image.setPixelRgb(
          x,
          y,
          buffer.getR(x, y),
          buffer.getG(x, y),
          buffer.getB(x, y),
        );
      }
    }

    final bytes = img.encodePng(image);

    final file = File('${Directory.systemTemp.path}/minifas_debug_crop.png');

    await file.writeAsBytes(bytes);

    debugPrint('MiniFASNet debug crop saved: ${file.path}');

    return file;
  }

  void _logTensorStats(String label, List<List<List<List<double>>>> input) {
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;
    double sum = 0.0;
    var count = 0;

    for (final channel in input[0]) {
      for (final row in channel) {
        for (final value in row) {
          if (value < minValue) {
            minValue = value;
          }

          if (value > maxValue) {
            maxValue = value;
          }

          sum += value;
          count++;
        }
      }
    }

    final mean = sum / count;

    debugPrint(
      'MiniFAS $label tensor stats: '
      'min=${minValue.toStringAsFixed(6)}, '
      'max=${maxValue.toStringAsFixed(6)}, '
      'mean=${mean.toStringAsFixed(6)}, '
      'count=$count',
    );

    debugPrint(
      'MiniFAS $label tensor sample: '
      'C0=${input[0][0][40][40].toStringAsFixed(6)}, '
      'C1=${input[0][1][40][40].toStringAsFixed(6)}, '
      'C2=${input[0][2][40][40].toStringAsFixed(6)}',
    );
  }

  // Future<File> _saveDebugInputImage(face_auth.FaceImageBuffer buffer) async {
  //   final image = img.Image(width: buffer.width, height: buffer.height);
  //
  //   for (var y = 0; y < buffer.height; y++) {
  //     for (var x = 0; x < buffer.width; x++) {
  //       image.setPixelRgb(
  //         x,
  //         y,
  //         buffer.getR(x, y),
  //         buffer.getG(x, y),
  //         buffer.getB(x, y),
  //       );
  //     }
  //   }
  //
  //   final bytes = img.encodePng(image);
  //
  //   final directory = await getExternalStorageDirectory();
  //
  //   if (directory == null) {
  //     throw Exception('Could not access external storage.');
  //   }
  //
  //   final file = File('${directory.path}/minifas_80x80_input.png');
  //
  //   await file.writeAsBytes(bytes);
  //
  //   debugPrint('MiniFASNet 80x80 input saved: ${file.path}');
  //
  //   return file;
  // }

  @override
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;

    faceDetector.dispose();
  }
}

class _CropRect {
  const _CropRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final int left;
  final int top;
  final int width;
  final int height;
}
