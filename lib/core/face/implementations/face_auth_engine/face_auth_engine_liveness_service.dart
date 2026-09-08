// import 'dart:io';
//
// import 'package:face_auth_engine/face_auth_engine.dart' as face_auth;
//
// import '../../models/liveness_verification_result.dart';
// import '../../services/liveness_service.dart';
// import 'image_face_provider.dart';
// import 'mlkit_face_detector_provider.dart';
//
// class FaceAuthEngineLivenessService implements LivenessService {
//   FaceAuthEngineLivenessService({
//     face_auth.LivenessOptions options = const face_auth.LivenessOptions(
//       threshold: 0.5,
//       outputIndex: 0,
//       outputIsSpoofProbability: false,
//     ),
//   }) : _options = options {
//     _detector = MlKitFaceDetectorProvider();
//     _imageProvider = ImageFaceProvider();
//   }
//
//   final face_auth.LivenessOptions _options;
//
//   late final MlKitFaceDetectorProvider _detector;
//   late final ImageFaceProvider _imageProvider;
//
//   late final Future<face_auth.LivenessDetector> _detectorFuture =
//       face_auth.LivenessDetector.create(
//         faceDetector: _detector,
//         imageProvider: _imageProvider,
//         options: _options,
//       );
//
//   @override
//   Future<LivenessVerificationResult> checkLiveness(File imageFile) async {
//     final detector = await _detectorFuture;
//
//     final result = await detector.detectLiveness(imageFile);
//
//     return LivenessVerificationResult(
//       isLive: result.isLive,
//       score: result.score,
//       durationMs: result.duration.inMilliseconds,
//       rejectionReason: result.rejectionReason.name,
//       laplacian: result.laplacian,
//       brightness: result.brightness,
//     );
//   }
//
//   @override
//   Future<void> dispose() async {
//     final detector = await _detectorFuture;
//
//     await detector.dispose();
//
//     _detector.dispose();
//   }
// }
