import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/face/implementations/face_auth_engine/image_face_provider.dart';
import '../../../core/face/implementations/face_auth_engine/mlkit_face_detector_provider.dart';
import '../../../core/face/implementations/minifasnet/mini_fas_liveness_service.dart';
import '../../../core/face/models/liveness_verification_result.dart';

class LivenessTestController extends GetxController {
  late final MiniFasLivenessService _livenessService;

  final ImagePicker _imagePicker = ImagePicker();

  final selectedImage = Rxn<File>();
  final result = Rxn<LivenessVerificationResult>();

  final isProcessing = false.obs;
  final errorMessage = RxnString();

  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();

    _livenessService = MiniFasLivenessService(
      faceDetector: MlKitFaceDetectorProvider(),
      imageProvider: ImageFaceProvider(),
    );
  }

  Future<void> pickAndTest() async {
    errorMessage.value = null;
    result.value = null;

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

    try {
      // Initialize MiniFASNet only once.
      if (!_isInitialized) {
        await _livenessService.initialize();
        _isInitialized = true;
      }

      result.value = await _livenessService.checkLiveness(file);
    } catch (e, stackTrace) {
      errorMessage.value = e.toString();

      debugPrint('MiniFASNet liveness error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isProcessing.value = false;
    }
  }

  Future<File> loadReferenceImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/image_T1.jpg');

    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );

    return file;
  }

  Future<void> testReferenceImage() async {
    errorMessage.value = null;
    result.value = null;
    isProcessing.value = true;

    try {
      if (!_isInitialized) {
        await _livenessService.initialize();
        _isInitialized = true;
      }

      final file = await loadReferenceImage('assets/test_images/image_T1.jpg');

      selectedImage.value = file;

      result.value = await _livenessService.checkLiveness(file);
    } catch (e, stackTrace) {
      errorMessage.value = e.toString();

      debugPrint('Reference image test failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isProcessing.value = false;
    }
  }

  @override
  Future<void> onClose() async {
    await _livenessService.dispose();
    super.onClose();
  }
}
