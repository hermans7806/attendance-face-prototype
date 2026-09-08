import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/active_liveness_test_controller.dart';

class ActiveLivenessTestScreen extends GetView<ActiveLivenessTestController> {
  const ActiveLivenessTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Liveness Test')),
      body: Obx(() {
        if (controller.errorMessage.value != null) {
          return _buildError();
        }

        if (!controller.isInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildCamera();
      }),
    );
  }

  Widget _buildCamera() {
    final camera = controller.cameraController;

    if (camera == null || !camera.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(camera),

        _buildFaceGuide(),

        _buildInstruction(),

        _buildDebugInfo(),

        _buildResult(),

        _buildRetryButton(),
      ],
    );
  }

  Widget _buildFaceGuide() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 340,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(160),
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction() {
    return Positioned(
      left: 20,
      right: 20,
      top: 30,
      child: Obx(
        () => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            controller.instruction.value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 20,
      child: Obx(
        () => Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black.withValues(alpha: 0.65),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phase: '
                  '${controller.phase.value.name}',
                ),
                Text(
                  'Face: '
                  '${controller.detectedFace.value}',
                ),
                Text(
                  'Left eye: '
                  '${controller.leftEyeProbability.value?.toStringAsFixed(3) ?? '-'}',
                ),
                Text(
                  'Right eye: '
                  '${controller.rightEyeProbability.value?.toStringAsFixed(3) ?? '-'}',
                ),
                Text(
                  'Average: '
                  '${controller.eyeOpenProbability.value?.toStringAsFixed(3) ?? '-'}',
                ),
                Text(
                  'Smile: '
                  '${controller.smileProbability.value?.toStringAsFixed(3) ?? '-'}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Obx(() {
      final result = controller.result.value;

      if (result == null) {
        return const SizedBox.shrink();
      }

      final passed = result.passed;

      return Center(
        child: Container(
          margin: const EdgeInsets.all(30),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: passed ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                passed ? 'Liveness Passed' : 'Liveness Failed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${result.duration.inMilliseconds} ms',
                style: const TextStyle(color: Colors.white70),
              ),
              if (result.reason != null) ...[
                const SizedBox(height: 8),
                Text(
                  result.reason!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRetryButton() {
    return Obx(() {
      if (controller.result.value == null) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: 30,
        right: 30,
        bottom: 160,
        child: ElevatedButton(
          onPressed: controller.retry,
          child: const Text('Try Again'),
        ),
      );
    });
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              controller.errorMessage.value ?? 'Unknown error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.initialize,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
