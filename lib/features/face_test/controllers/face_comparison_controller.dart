import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/face/implementations/face_auth_engine/face_auth_engine_service.dart';
import '../../../core/face/models/face_comparison_result.dart';

class FaceComparisonController extends GetxController {
  final FaceAuthEngineService _faceService = FaceAuthEngineService();

  final ImagePicker _imagePicker = ImagePicker();

  final imageA = Rxn<File>();
  final imageB = Rxn<File>();

  final isProcessing = false.obs;
  final result = Rxn<FaceComparisonResult>();
  final errorMessage = RxnString();

  Future<void> pickImageA() async {
    final image = await _pickImage();

    if (image == null) return;

    imageA.value = File(image.path);
    result.value = null;
    errorMessage.value = null;
  }

  Future<void> pickImageB() async {
    final image = await _pickImage();

    if (image == null) return;

    imageB.value = File(image.path);
    result.value = null;
    errorMessage.value = null;
  }

  Future<void> compare() async {
    final first = imageA.value;
    final second = imageB.value;

    if (first == null || second == null) {
      errorMessage.value = 'Please select both photos.';
      return;
    }

    isProcessing.value = true;
    errorMessage.value = null;
    result.value = null;

    try {
      result.value = await _faceService.compareFaces(first, second);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isProcessing.value = false;
    }
  }

  Future<XFile?> _pickImage() {
    return _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
  }

  @override
  void onClose() {
    _faceService.dispose();
    super.onClose();
  }
}
