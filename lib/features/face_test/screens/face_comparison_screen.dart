import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/face_comparison_controller.dart';

class FaceComparisonScreen extends GetView<FaceComparisonController> {
  const FaceComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Comparison')),
      body: Obx(() {
        final imageA = controller.imageA.value;
        final imageB = controller.imageB.value;
        final result = controller.result.value;
        final error = controller.errorMessage.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ImageCard(
                      title: 'Photo A',
                      image: imageA,
                      onPressed: controller.pickImageA,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImageCard(
                      title: 'Photo B',
                      image: imageB,
                      onPressed: controller.pickImageB,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.isProcessing.value
                      ? null
                      : controller.compare,
                  icon: const Icon(Icons.compare),
                  label: const Text('Compare Faces'),
                ),
              ),

              if (controller.isProcessing.value) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Comparing faces...'),
              ],

              if (result != null) ...[
                const SizedBox(height: 32),

                const Text('L2 Distance', style: TextStyle(fontSize: 16)),

                const SizedBox(height: 4),

                Text(
                  result.distance.toStringAsFixed(6),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Text('Threshold: ${result.threshold.toStringAsFixed(6)}'),

                const SizedBox(height: 24),

                Text(
                  result.isMatch ? '✓ SAME PERSON' : '✗ DIFFERENT PERSON',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: result.isMatch ? Colors.green : Colors.red,
                  ),
                ),
              ],

              if (error != null) ...[
                const SizedBox(height: 20),
                Text(error, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({
    required this.title,
    required this.image,
    required this.onPressed,
  });

  final String title;
  final dynamic image;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
            ),
            clipBehavior: Clip.antiAlias,
            child: image != null
                ? Image.file(image, fit: BoxFit.cover)
                : const Center(child: Icon(Icons.person, size: 64)),
          ),
        ),

        const SizedBox(height: 8),

        OutlinedButton(onPressed: onPressed, child: const Text('Select')),
      ],
    );
  }
}
