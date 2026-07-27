import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

/// Result of a receipt download: where the file was saved and whether that
/// location is the user-visible public Downloads folder.
class ReceiptSaveResult {
  const ReceiptSaveResult({required this.filePath, required this.savedToDownloads});

  final String filePath;
  final bool savedToDownloads;
}

/// Downloads a server-generated receipt PDF from its (temporary) URL, saves it
/// to the device's Downloads folder, then opens the system save/share sheet.
///
/// The URL points at a third-party blob host (Azure), so it is fetched with a
/// dedicated [Dio] instance — NOT the app's [ApiClient] — to avoid attaching
/// the user's auth token and app headers to an external request.
class SessionReceiptDownloader {
  const SessionReceiptDownloader._();

  static const _timeout = Duration(seconds: 60);

  /// The public Downloads directory on Android. path_provider can't resolve it
  /// (`getDownloadsDirectory` is desktop/iOS-only), so it's referenced directly.
  static const _androidDownloadsPath = '/storage/emulated/0/Download';

  /// Fetches the PDF at [receiptUrl], writes it to disk, and hands it to the OS
  /// share/save sheet. Returns where the file landed.
  ///
  /// Throws a [ReceiptDownloadException] (with a user-facing message) if the
  /// download, the disk write, or the share fails.
  static Future<ReceiptSaveResult> downloadAndShare({
    required String receiptUrl,
    required int sessionId,
  }) async {
    final bytes = await _fetchBytes(receiptUrl);
    final filename = 'HUBCO_Receipt_$sessionId.pdf';

    final saved = await _saveToDisk(bytes, filename);

    try {
      // Share the on-disk file so the sheet reflects the saved document (and so
      // the user can re-share/move it). Falls back to sharing the raw bytes.
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e, st) {
      // The file is already saved — a failed share sheet isn't fatal, but let
      // the caller know sharing didn't open.
      log('[Receipt] share failed (file saved at ${saved.filePath}): $e\n$st');
      throw ReceiptDownloadException(
        saved.savedToDownloads
            ? 'Saved to Downloads, but the share sheet could not open.'
            : 'Receipt saved, but the share sheet could not open.',
      );
    }

    return saved;
  }

  static Future<Uint8List> _fetchBytes(String url) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        responseType: ResponseType.bytes,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );
    try {
      final response = await dio.get<List<int>>(url);
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw const ReceiptDownloadException(
          'The receipt file is empty. Please try again.',
        );
      }
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      log('[Receipt] fetch failed (${e.response?.statusCode}): ${e.message}');
      final isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      throw ReceiptDownloadException(
        isTimeout
            ? 'The download timed out. Please try again.'
            : 'Could not download the receipt. Please try again.',
      );
    } finally {
      dio.close(force: true);
    }
  }

  /// Writes [bytes] to the Downloads folder (Android) or the app documents
  /// directory (iOS — no shared Downloads exists), with an app-storage fallback
  /// when the public folder isn't writable on this device.
  static Future<ReceiptSaveResult> _saveToDisk(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      if (Platform.isAndroid) {
        await _ensureAndroidStoragePermission();
        final downloads = Directory(_androidDownloadsPath);
        if (await downloads.exists()) {
          try {
            final file = File('${downloads.path}/$filename');
            await file.writeAsBytes(bytes, flush: true);
            log('[Receipt] saved to Downloads: ${file.path}');
            return ReceiptSaveResult(
              filePath: file.path,
              savedToDownloads: true,
            );
          } on FileSystemException catch (e) {
            // Scoped storage blocked the write — fall through to app storage.
            log('[Receipt] Downloads write blocked, falling back: $e');
          }
        }
      }
      // iOS, or Android fallback: app-visible storage (shareable, and on iOS
      // exposed in Files when the app enables it).
      final dir = await _appStorageDir();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      log('[Receipt] saved to app storage: ${file.path}');
      return ReceiptSaveResult(filePath: file.path, savedToDownloads: false);
    } on ReceiptDownloadException {
      rethrow;
    } catch (e, st) {
      log('[Receipt] save failed: $e\n$st');
      throw const ReceiptDownloadException(
        'Could not save the receipt to your device. Please try again.',
      );
    }
  }

  static Future<Directory> _appStorageDir() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    }
    return getApplicationDocumentsDirectory();
  }

  /// Requests legacy storage permission on Android 12 and below. On Android 13+
  /// the request is a no-op (writing to Download needs no permission), and a
  /// denial isn't fatal — the write itself falls back to app storage.
  static Future<void> _ensureAndroidStoragePermission() async {
    try {
      final status = await Permission.storage.status;
      if (status.isGranted || status.isPermanentlyDenied || status.isRestricted) {
        return;
      }
      await Permission.storage.request();
    } catch (e) {
      // permission_handler can throw on platforms where the permission isn't
      // declared — ignore; the disk-write fallback covers a denied write.
      log('[Receipt] storage permission check skipped: $e');
    }
  }
}

/// A failure while downloading, saving, or opening the receipt, with a message
/// safe to show to the user.
class ReceiptDownloadException implements Exception {
  const ReceiptDownloadException(this.message);

  final String message;

  @override
  String toString() => 'ReceiptDownloadException: $message';
}
