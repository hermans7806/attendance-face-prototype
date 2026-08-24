import 'package:get/get.dart';

import '../../features/face_test/controllers/face_comparison_controller.dart';
import '../../features/face_test/controllers/face_test_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // ============================================================
    // AUTH / DASHBOARD
    // ============================================================

    // Get.put(AuthService(), permanent: true);

    // Get.put(AuthController(Get.find()), permanent: true);

    Get.lazyPut<FaceTestController>(() => FaceTestController());
    Get.lazyPut<FaceComparisonController>(() => FaceComparisonController());
  }
}
