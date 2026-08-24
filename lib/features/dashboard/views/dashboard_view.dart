import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_theme.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../models/attendance_record.dart';
import '../models/today_attendance.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceController = Get.find<AttendanceController>();

    return Scaffold(
      body: SafeArea(
        child: Obx(
          () => RefreshIndicator(
            onRefresh: controller.refreshData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // ==========================================================
                // LOGO
                // ==========================================================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/absensi_logo.png', height: 50),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ==========================================================
                // GREETING
                // ==========================================================
                _Greeting(name: controller.staffName.value),

                Obx(
                  () => Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _SummaryChip(
                        label: 'Penalty',
                        value: '-${controller.monthlyPenalty}',
                        color: Colors.red,
                      ),
                      _SummaryChip(
                        label: 'Lembur',
                        value: _formatOvertime(
                          controller.monthlyOvertimeMinutes,
                        ),
                        color: Colors.blue,
                      ),
                      _SummaryChip(
                        label: 'Total Hari',
                        value: controller.monthlyWorkDays.toStringAsFixed(2),
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==========================================================
                // TODAY CARD
                // ==========================================================
                _TodayCard(today: controller.today.value),

                const SizedBox(height: 8),

                // ==========================================================
                // STATUS
                // ==========================================================
                _Status(today: controller.today.value),

                const SizedBox(height: 16),

                // ==========================================================
                // REQUEST BUTTONS
                // ==========================================================
                _Actions(controller: controller),

                const SizedBox(height: 26),

                // ==========================================================
                // HISTORY TITLE
                // ==========================================================
                const Text(
                  'Riwayat Absensi Bulan Ini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                // ==========================================================
                // HISTORY
                // ==========================================================
                if (controller.isLoading.value)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (controller.history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: Text('Belum ada data')),
                  )
                else
                  ...controller.history.map(_HistoryCard.new),

                const SizedBox(height: 12),

                // ==========================================================
                // ATTENDANCE BUTTON
                // ==========================================================
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Obx(
          () => Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _AttendanceButton(
              today: controller.today.value,
              attendanceController: attendanceController,
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// GREETING
// ==========================================================================

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black54, fontSize: 13),
              children: [
                const TextSpan(text: 'Selamat datang, '),
                TextSpan(
                  text: name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: Get.find<AuthController>().signOut,
          icon: const Icon(Icons.logout, color: Colors.red),
        ),
      ],
    );
  }
}

// ==========================================================================
// TODAY CARD
// ==========================================================================

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.today});

  final TodayAttendance today;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: .25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Time(
              label: 'Check-in',
              icon: Icons.login,
              time: today.checkIn,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _Time(
              label: 'Check-out',
              icon: Icons.logout,
              time: today.checkOut,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// TIME
// ==========================================================================

class _Time extends StatelessWidget {
  const _Time({required this.label, required this.icon, this.time});

  final String label;
  final IconData icon;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          _formatTime(time),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

// ==========================================================================
// STATUS
// ==========================================================================

class _Status extends StatelessWidget {
  const _Status({required this.today});

  final TodayAttendance today;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (today.status) {
      TodayAttendanceStatus.notCheckedIn => ('Belum Check-in', Colors.red),
      TodayAttendanceStatus.checkedIn => ('Sudah Check-in', Colors.orange),
      TodayAttendanceStatus.completed => ('Absensi Selesai', Colors.green),
    };

    return Center(
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ==========================================================================
// REQUEST BUTTONS
// ==========================================================================

class _Actions extends StatelessWidget {
  const _Actions({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.today.value.status;

      final hasCheckoutRequest = controller.checkoutRequestType != null;

      Widget btn(String label, VoidCallback? onTap) {
        return Expanded(
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                btn('Ijin Telat', () async {
                  final now = DateTime.now();

                  final alreadyCheckedIn =
                      status != TodayAttendanceStatus.notCheckedIn;

                  final firstAllowedDate = alreadyCheckedIn
                      ? DateTime(now.year, now.month, now.day + 1)
                      : DateTime(now.year, now.month, now.day);

                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: firstAllowedDate,
                    firstDate: firstAllowedDate,
                    lastDate: now.add(const Duration(days: 30)),
                  );

                  if (selectedDate == null || !context.mounted) {
                    return;
                  }

                  final formatted =
                      '${selectedDate.day} '
                      '${_monthName(selectedDate.month)}';

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Konfirmasi'),
                      content: Text(
                        'Ijin telat untuk '
                        '$formatted?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Kirim'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await controller.requestLateCheckin(selectedDate);
                  }
                }),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                btn(
                  'Pulang Cepat',
                  (status != TodayAttendanceStatus.checkedIn ||
                          hasCheckoutRequest)
                      ? null
                      : controller.requestEarlyCheckout,
                ),

                const SizedBox(width: 10),

                btn(
                  'Lembur',
                  (status != TodayAttendanceStatus.checkedIn ||
                          hasCheckoutRequest)
                      ? null
                      : controller.requestOvertime,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ==========================================================================
// ATTENDANCE BUTTON
// ==========================================================================

class _AttendanceButton extends StatelessWidget {
  const _AttendanceButton({
    required this.today,
    required this.attendanceController,
  });

  final TodayAttendance today;
  final AttendanceController attendanceController;

  @override
  Widget build(BuildContext context) {
    final isCheckIn = today.status == TodayAttendanceStatus.notCheckedIn;

    final isCheckOut = today.status == TodayAttendanceStatus.checkedIn;

    final isCompleted = today.status == TodayAttendanceStatus.completed;

    final label = isCheckIn
        ? 'Check In'
        : isCheckOut
        ? 'Check Out'
        : 'Absensi Selesai';

    return Obx(() {
      final loading = attendanceController.isLoading.value;

      return SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton.icon(
          onPressed: isCompleted || loading
              ? null
              : () async {
                  await attendanceController.startAttendanceFlow(
                    isCheckIn ? 'checkin' : 'checkout',
                  );

                  await Get.find<DashboardController>().refreshData();
                },
          icon: Icon(
            Icons.camera_alt,
            color: isCompleted ? Colors.white70 : Colors.white,
          ),
          label: Text(
            loading ? 'Memproses...' : label,
            style: const TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isCompleted ? Colors.grey : AppTheme.gold,
            disabledBackgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    });
  }
}

// ==========================================================================
// HISTORY
// ==========================================================================

class _HistoryCard extends StatelessWidget {
  const _HistoryCard(this.record);

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final penalty = record.latePenalty + record.checkoutPenalty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ==========================================================
          // DATE
          // ==========================================================
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.date.day}/${record.date.month}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _dayName(record.date.weekday),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ==========================================================
          // CHECK-IN / CHECK-OUT
          // ==========================================================
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: _HistoryTime(label: 'Check-in', time: record.checkIn),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: _HistoryTime(
                    label: 'Check-out',
                    time: record.checkOut,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ==========================================================
          // ATTENDANCE SUMMARY
          // ==========================================================
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _HistoryMetric(
                  label: 'Penalty',
                  value: '-$penalty',
                  color: penalty > 0 ? Colors.red : Colors.grey.shade600,
                ),

                const SizedBox(height: 3),

                _HistoryMetric(
                  label: 'Kerja',
                  value: record.workFraction.toStringAsFixed(2),
                  color: Colors.blue,
                ),

                if (record.overtimeMinutes > 0) ...[
                  const SizedBox(height: 3),
                  _HistoryMetric(
                    label: 'Lembur',
                    value: _formatOvertime(record.overtimeMinutes),
                    color: Colors.orange,
                  ),
                ],

                if (record.mealAllowanceEarned > 0) ...[
                  const SizedBox(height: 3),
                  _HistoryMetric(
                    label: 'U.Makan',
                    value: record.mealAllowanceEarned.toString(),
                    color: Colors.green,
                  ),
                ],

                if (record.approvalStatus != null) ...[
                  const SizedBox(height: 3),
                  _ApprovalChip(status: record.approvalStatus!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// HISTORY TIME
// ==========================================================================

class _HistoryTime extends StatelessWidget {
  const _HistoryTime({required this.label, this.time});

  final String label;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(
          _formatTime(time),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ==========================================================================
// HISTORY METRIC
// ==========================================================================

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// SUMMARY CHIP
// ==========================================================================

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: color),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// APPROVAL CHIP
// ==========================================================================
class _ApprovalChip extends StatelessWidget {
  const _ApprovalChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final isApproved = normalized == 'approved' || normalized == 'disetujui';

    final isRejected = normalized == 'rejected' || normalized == 'ditolak';

    final color = isApproved
        ? Colors.green
        : isRejected
        ? Colors.red
        : Colors.orange;

    final label = isApproved
        ? 'Disetujui'
        : isRejected
        ? 'Ditolak'
        : status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ==========================================================================
// HELPERS
// ==========================================================================

String _formatTime(DateTime? time) {
  return time == null
      ? '--:--'
      : '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}';
}

String _dayName(int day) {
  return const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][day - 1];
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  return months[month - 1];
}

String _formatOvertime(int minutes) {
  if (minutes <= 0) {
    return '0m';
  }

  final hours = minutes ~/ 60;
  final remaining = minutes % 60;

  if (hours == 0) {
    return '${remaining}m';
  }

  if (remaining == 0) {
    return '${hours}h';
  }

  return '${hours}h ${remaining}m';
}
