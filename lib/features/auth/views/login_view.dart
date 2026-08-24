import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                /// 🔷 LOGO ROW (FIXED)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/absensi_logo.png', height: 50),
                  ],
                ),

                const SizedBox(height: 50),

                /// TITLE
                Text(
                  "Staff Login",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  'Login to manage attendance',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: AuthController.to.isSigningIn.value
                          ? null
                          : AuthController.to.signInWithGoogle,
                      icon: AuthController.to.isSigningIn.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Image.asset('assets/google_logo.png', height: 22),
                      label: Text(
                        AuthController.to.isSigningIn.value
                            ? 'Signing in...'
                            : 'Sign in with Google',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
