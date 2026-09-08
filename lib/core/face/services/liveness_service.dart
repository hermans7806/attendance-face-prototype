import 'dart:io';

import '../models/liveness_verification_result.dart';

abstract class LivenessService {
  Future<LivenessVerificationResult> checkLiveness(File imageFile);

  Future<void> dispose();
}
