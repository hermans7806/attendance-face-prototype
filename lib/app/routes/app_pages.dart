import 'package:attendance_face_prototype/features/dashboard/views/dashboard_view.dart';
import 'package:get/get.dart';

import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/pending_approval_view.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const pendingApproval = '/pending-approval';
  static const dashboard = '/dashboard';
}

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.login, page: LoginView.new),
    GetPage(name: AppRoutes.pendingApproval, page: PendingApprovalView.new),
    GetPage(name: AppRoutes.dashboard, page: DashboardView.new),
  ];
}
