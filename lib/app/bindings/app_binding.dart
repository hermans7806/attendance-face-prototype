import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/services/auth_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // ============================================================
    // AUTH / DASHBOARD
    // ============================================================

    Get.put(AuthService(), permanent: true);

    Get.put(AuthController(Get.find()), permanent: true);
  }
}
