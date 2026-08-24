import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_pages.dart';
import '../models/staff_account.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  AuthController(this._authService);

  static AuthController get to => Get.find();

  final AuthService _authService;
  final account = Rxn<StaffAccount>();
  final isResolving = true.obs;
  final isSigningIn = false.obs;
  StreamSubscription<User?>? _subscription;

  @override
  void onReady() {
    super.onReady();
    _subscription = _authService.authChanges.listen(_resolveSession);
  }

  Future<void> _resolveSession(User? user) async {
    isResolving.value = true;
    if (user == null) {
      account.value = null;
      isResolving.value = false;
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    try {
      final staff = await _authService.syncStaffAccount(user);
      account.value = staff;
      if (staff == null) {
        Get.offAllNamed(AppRoutes.pendingApproval);
      } else if (!staff.isActive) {
        await _authService.signOut();
        Get.snackbar(
          'Account Disabled',
          'Hubungi administrator bila terjadi kesalahan.',
        );
      } else {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } catch (_) {
      Get.snackbar(
        'Tidak dapat memuat akun',
        'Periksa koneksi internet lalu coba lagi.',
      );
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isResolving.value = false;
    }
  }

  Future<void> signOut() => _authService.signOut();

  Future<void> signInWithGoogle() async {
    if (isSigningIn.value) return;
    try {
      isSigningIn.value = true;
      await _authService.signInWithGoogle();
    } catch (_) {
      Get.snackbar(
        'Login Failed',
        'Tidak dapat masuk dengan Google. Silakan coba lagi.',
      );
    } finally {
      isSigningIn.value = false;
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
