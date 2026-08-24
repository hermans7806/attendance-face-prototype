import 'dart:io';

import '../models/face_comparison_result.dart';

abstract class FaceRecognitionService {
  Future<List<double>> generateEmbedding(File imageFile);

  Future<bool> verifyFace(File imageFile, List<double> enrolledEmbedding);

  Future<FaceComparisonResult> compareFaces(File imageFile1, File imageFile2);

  void dispose();
}
