import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/face/models/liveness_verification_result.dart';
import '../controllers/liveness_test_controller.dart';

class LivenessTestScreen extends GetView<LivenessTestController> {
  const LivenessTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liveness Test')),
      body: Obx(() {
        final image = controller.selectedImage.value;
        final result = controller.result.value;
        final error = controller.errorMessage.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image preview
              Container(
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade200,
                ),
                clipBehavior: Clip.antiAlias,
                child: image != null
                    ? Image.file(image, fit: BoxFit.contain)
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.face_retouching_natural, size: 64),
                            SizedBox(height: 12),
                            Text('Select a face photo'),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // Pick image
              FilledButton.icon(
                onPressed: controller.isProcessing.value
                    ? null
                    : controller.pickAndTest,
                icon: const Icon(Icons.photo_library),
                label: const Text('Select Photo'),
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: controller.isProcessing.value
                    ? null
                    : controller.testReferenceImage,
                icon: const Icon(Icons.science),
                label: const Text('Test Official image_F1'),
              ),

              const SizedBox(height: 24),

              // Processing state
              if (controller.isProcessing.value)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Running liveness detection...',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // Result
              if (result != null && !controller.isProcessing.value)
                _LivenessResultCard(result: result),

              // Error
              if (error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      error,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _LivenessResultCard extends StatelessWidget {
  const _LivenessResultCard({required this.result});

  final LivenessVerificationResult result;

  @override
  Widget build(BuildContext context) {
    final isLive = result.isLive;
    final liveScore = result.liveScore;
    final printScore = result.printScore;
    final replayScore = result.replayScore;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Liveness Result',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isLive ? Colors.green.shade50 : Colors.red.shade50,
              ),
              child: Column(
                children: [
                  Icon(
                    isLive ? Icons.verified_user : Icons.gpp_bad,
                    size: 48,
                    color: isLive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLive ? 'LIVE' : 'SPOOF / NOT LIVE',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isLive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _ResultRow(
              label: 'Live probability',
              value: liveScore.toStringAsFixed(4),
            ),

            _ResultRow(
              label: 'Print spoof',
              value: printScore.toStringAsFixed(4),
            ),

            _ResultRow(
              label: 'Replay spoof',
              value: replayScore.toStringAsFixed(4),
            ),

            _ResultRow(
              label: 'Combined spoof',
              value: result.spoofScore.toStringAsFixed(4),
            ),

            _ResultRow(label: 'Predicted class', value: result.predictedClass),

            _ResultRow(
              label: 'Processing time',
              value: '${result.durationMs} ms',
            ),

            _ResultRow(
              label: 'Rejection reason',
              value: result.rejectionReason,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
