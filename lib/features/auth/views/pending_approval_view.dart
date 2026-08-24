import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

class PendingApprovalView extends StatelessWidget {
  const PendingApprovalView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 54,
                  color: AppTheme.primaryBlue,
                ),
                SizedBox(height: 20),
                Text(
                  'Menunggu Persetujuan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Akun Anda belum terdaftar sebagai staf. Hubungi administrator untuk persetujuan.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
