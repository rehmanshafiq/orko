import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Image formats the profile-picture API accepts directly.
const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png'};

/// Ensures [sourcePath] points to an upload-friendly image.
///
/// If the file is already a jpg/jpeg/png, its path is returned unchanged.
/// Otherwise the image is decoded and re-encoded to PNG on a background
/// isolate (via [compute]) and written next to the source, returning the new
/// path.
///
/// Throws [UnsupportedImageException] when the bytes can't be decoded (e.g. an
/// unsupported/corrupt format).
Future<String> ensureUploadableImage(String sourcePath) async {
  final extension = _extensionOf(sourcePath);
  if (_allowedExtensions.contains(extension)) {
    return sourcePath;
  }

  final bytes = await File(sourcePath).readAsBytes();

  // Decode + re-encode to PNG off the UI thread.
  final pngBytes = await compute(_encodeToPng, bytes);
  if (pngBytes == null) {
    throw const UnsupportedImageException(
      'Unsupported image format. Please choose a JPG or PNG image.',
    );
  }

  final dir = File(sourcePath).parent.path;
  final outPath =
      '$dir/profile_${DateTime.now().millisecondsSinceEpoch}.png';
  await File(outPath).writeAsBytes(pngBytes, flush: true);
  return outPath;
}

/// Lower-cased file extension (without the dot), or '' when there is none.
String _extensionOf(String path) {
  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

/// Runs in a background isolate: decodes [input] and re-encodes it as PNG.
/// Returns null when the bytes can't be decoded.
Uint8List? _encodeToPng(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) return null;
  return img.encodePng(decoded);
}

/// Thrown when a picked image can't be decoded into an uploadable format.
class UnsupportedImageException implements Exception {
  const UnsupportedImageException(this.message);

  final String message;

  @override
  String toString() => message;
}
