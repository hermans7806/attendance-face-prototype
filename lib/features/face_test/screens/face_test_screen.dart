import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/face_test_controller.dart';

class FaceTestScreen extends GetView<FaceTestController> {
  const FaceTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Engine Test')),
      body: Obx(() {
        final image = controller.selectedImage.value;
        final embedding = controller.embedding.value;
        final error = controller.errorMessage.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(image, height: 300, fit: BoxFit.cover),
                )
              else
                Container(
                  height: 300,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade200,
                  ),
                  child: const Text('Select a face photo'),
                ),

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: controller.isProcessing.value
                    ? null
                    : controller.pickAndProcessImage,
                icon: const Icon(Icons.face),
                label: const Text('Select Face Photo'),
              ),

              const SizedBox(height: 24),

              if (controller.isProcessing.value)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing face...'),
                    ],
                  ),
                ),

              if (embedding != null) ...[
                _ResultRow(label: 'Embedding', value: '✓ Generated'),
                _ResultRow(label: 'Dimensions', value: '${embedding.length}'),
                _ResultRow(
                  label: 'Processing',
                  value: '${controller.processingTimeMs.value} ms',
                ),
                const SizedBox(height: 16),
                const Text(
                  'First 10 values',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  embedding
                      .take(10)
                      .map((value) => value.toStringAsFixed(6))
                      .join(', '),
                ),
              ],

              if (error != null) ...[
                const SizedBox(height: 16),
                Text(error, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        );
      }),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
