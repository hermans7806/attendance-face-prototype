import 'dart:io';
import 'dart:typed_data';

import 'package:face_auth_engine/face_auth_engine.dart' as face_auth;
import 'package:image/image.dart' as img;

class ImageFaceProvider implements face_auth.FaceImageProvider {
  @override
  Future<face_auth.FaceImageBuffer> loadImage(File file) async {
    final bytes = await file.readAsBytes();

    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Could not decode image.');
    }

    // Fix EXIF orientation before converting to RGB.
    final oriented = img.bakeOrientation(decoded);

    final rgb = _toRgb(oriented);

    return face_auth.FaceImageBuffer(
      width: oriented.width,
      height: oriented.height,
      pixels: rgb,
    );
  }

  @override
  Future<face_auth.FaceImageBuffer> resize(
    face_auth.FaceImageBuffer image,
    int width,
    int height,
  ) async {
    final source = _toImage(image);

    final resized = img.copyResize(
      source,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );

    return face_auth.FaceImageBuffer(
      width: resized.width,
      height: resized.height,
      pixels: _toRgb(resized),
    );
  }

  @override
  Future<face_auth.FaceImageBuffer> crop(
    face_auth.FaceImageBuffer image,
    int x,
    int y,
    int width,
    int height,
  ) async {
    final source = _toImage(image);

    // Clamp crop rectangle to the actual image boundaries.
    final left = x.clamp(0, source.width);
    final top = y.clamp(0, source.height);

    final right = (x + width).clamp(0, source.width);
    final bottom = (y + height).clamp(0, source.height);

    final cropWidth = right - left;
    final cropHeight = bottom - top;

    if (cropWidth <= 0 || cropHeight <= 0) {
      throw ArgumentError('Invalid crop rectangle.');
    }

    final cropped = img.copyCrop(
      source,
      x: left,
      y: top,
      width: cropWidth,
      height: cropHeight,
    );

    return face_auth.FaceImageBuffer(
      width: cropped.width,
      height: cropped.height,
      pixels: _toRgb(cropped),
    );
  }

  Uint8List _toRgb(img.Image image) {
    final pixels = Uint8List(image.width * image.height * 3);

    var index = 0;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        pixels[index++] = pixel.r.toInt();
        pixels[index++] = pixel.g.toInt();
        pixels[index++] = pixel.b.toInt();
      }
    }

    return pixels;
  }

  img.Image _toImage(face_auth.FaceImageBuffer buffer) {
    final image = img.Image(width: buffer.width, height: buffer.height);

    var index = 0;

    for (var y = 0; y < buffer.height; y++) {
      for (var x = 0; x < buffer.width; x++) {
        image.setPixelRgb(
          x,
          y,
          buffer.pixels[index],
          buffer.pixels[index + 1],
          buffer.pixels[index + 2],
        );

        index += 3;
      }
    }

    return image;
  }
}
