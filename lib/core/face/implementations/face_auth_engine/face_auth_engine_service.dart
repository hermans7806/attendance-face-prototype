import 'dart:io';
import 'dart:math' as math;

import 'package:face_auth_engine/face_auth_engine.dart' as face_auth;

import '../../models/face_comparison_result.dart';
import '../../services/face_recognition_service.dart';
import 'image_face_provider.dart';
import 'mlkit_face_detector_provider.dart';

class FaceAuthEngineService implements FaceRecognitionService {
  FaceAuthEngineService({
    face_auth.FaceConfig config = face_auth.FaceConfig.defaultConfig,
  }) : _config = config {
    _detector = MlKitFaceDetectorProvider();
    _imageProvider = ImageFaceProvider();

    _engine = face_auth.FaceAuthEngine(
      faceDetector: _detector,
      imageProvider: _imageProvider,
      config: config,
    );
  }

  double _getRecognitionThreshold() {
    return _config.recognitionThreshold;
  }

  late final MlKitFaceDetectorProvider _detector;
  late final ImageFaceProvider _imageProvider;
  late final face_auth.FaceAuthEngine _engine;
  final face_auth.FaceConfig _config;

  @override
  Future<List<double>> generateEmbedding(File imageFile) {
    return _engine.convertToEmbedded(imageFile.path);
  }

  @override
  Future<bool> verifyFace(File imageFile, List<double> enrolledEmbedding) {
    return _engine.isThePersonTheSame(imageFile.path, enrolledEmbedding);
  }

  @override
  Future<FaceComparisonResult> compareFaces(
    File imageFile1,
    File imageFile2,
  ) async {
    final embedding1 = await _engine.convertToEmbedded(imageFile1.path);

    final embedding2 = await _engine.convertToEmbedded(imageFile2.path);

    if (embedding1.length != embedding2.length) {
      throw Exception(
        'Embedding dimensions do not match: '
        '${embedding1.length} vs ${embedding2.length}',
      );
    }

    var sum = 0.0;

    for (var i = 0; i < embedding1.length; i++) {
      final difference = embedding1[i] - embedding2[i];
      sum += difference * difference;
    }

    final distance = math.sqrt(sum);

    final threshold = _getRecognitionThreshold();

    return FaceComparisonResult(distance: distance, threshold: threshold);
  }

  @override
  void dispose() {
    _engine.dispose();
    _detector.dispose();
  }
}
