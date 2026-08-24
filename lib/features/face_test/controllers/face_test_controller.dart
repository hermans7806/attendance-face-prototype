import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/face/implementations/face_auth_engine/face_auth_engine_service.dart';

class FaceTestController extends GetxController {
  final FaceAuthEngineService _faceService = FaceAuthEngineService();
  final ImagePicker _imagePicker = ImagePicker();

  final selectedImage = Rxn<File>();
  final isProcessing = false.obs;
  final embedding = Rxn<List<double>>();
  final processingTimeMs = RxnInt();
  final errorMessage = RxnString();

  Future<void> pickAndProcessImage() async {
    errorMessage.value = null;
    embedding.value = null;
    processingTimeMs.value = null;

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    final file = File(image.path);
    selectedImage.value = file;

    isProcessing.value = true;

    final stopwatch = Stopwatch()..start();

    try {
      final result = await _faceService.generateEmbedding(file);

      stopwatch.stop();

      embedding.value = result;
      processingTimeMs.value = stopwatch.elapsedMilliseconds;

      debugPrint(
        'Face embedding generated: '
        '${result.length} dimensions',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      debugPrint('Face processing failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      errorMessage.value = e.toString();
    } finally {
      isProcessing.value = false;
    }
  }

  @override
  void onClose() {
    _faceService.dispose();
    super.onClose();
  }
}
