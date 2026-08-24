import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 52,
              color: AppTheme.primaryBlue,
            ),
            SizedBox(height: 18),
            CircularProgressIndicator(color: AppTheme.primaryBlue),
          ],
        ),
      ),
    );
  }
}
