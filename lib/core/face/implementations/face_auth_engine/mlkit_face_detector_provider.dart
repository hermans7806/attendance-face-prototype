import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:face_auth_engine/face_auth_engine.dart' as face_auth;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class MlKitFaceDetectorProvider implements face_auth.FaceDetectorProvider {
  MlKitFaceDetectorProvider()
    : _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: false,
          enableClassification: false,
          enableTracking: false,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

  final FaceDetector _detector;

  @override
  Future<face_auth.FaceDetectionResult> detectFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faces = await _detector.processImage(inputImage);

    if (faces.isEmpty) {
      throw Exception('No face detected.');
    }

    if (faces.length > 1) {
      throw Exception(
        'Multiple faces detected. Please ensure only one face is visible.',
      );
    }

    final face = faces.first;

    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final nose = face.landmarks[FaceLandmarkType.noseBase];
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];

    if (leftEye == null ||
        rightEye == null ||
        nose == null ||
        leftMouth == null ||
        rightMouth == null) {
      throw Exception('Could not detect all required facial landmarks.');
    }

    return face_auth.FaceDetectionResult(
      boundingBox: Rect.fromLTRB(
        face.boundingBox.left,
        face.boundingBox.top,
        face.boundingBox.right,
        face.boundingBox.bottom,
      ),
      landmarks: [
        face_auth.FaceLandmark(
          Point<int>(leftEye.position.x.round(), leftEye.position.y.round()),
        ),
        face_auth.FaceLandmark(
          Point<int>(rightEye.position.x.round(), rightEye.position.y.round()),
        ),
        face_auth.FaceLandmark(
          Point<int>(nose.position.x.round(), nose.position.y.round()),
        ),
        face_auth.FaceLandmark(
          Point<int>(
            leftMouth.position.x.round(),
            leftMouth.position.y.round(),
          ),
        ),
        face_auth.FaceLandmark(
          Point<int>(
            rightMouth.position.x.round(),
            rightMouth.position.y.round(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _detector.close();
  }
}
