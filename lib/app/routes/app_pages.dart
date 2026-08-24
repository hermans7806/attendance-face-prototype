import 'package:get/get.dart';

import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/pending_approval_view.dart';
import '../../features/dashboard/views/dashboard_view.dart';
import '../../features/face_test/screens/face_comparison_screen.dart';
import '../../features/face_test/screens/face_test_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const pendingApproval = '/pending-approval';
  static const dashboard = '/dashboard';
  static const faceTest = '/face-test';
  static const faceComparison = '/face-comparison';
}

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.login, page: LoginView.new),
    GetPage(name: AppRoutes.pendingApproval, page: PendingApprovalView.new),
    GetPage(name: AppRoutes.dashboard, page: DashboardView.new),
    GetPage(name: AppRoutes.faceTest, page: FaceTestScreen.new),
    GetPage(name: AppRoutes.faceComparison, page: FaceComparisonScreen.new),
  ];
}
