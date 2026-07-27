import 'package:orko_hubco/core/utils/app_logger.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

/// Result of a receipt download: where the file was staged on disk.
class ReceiptSaveResult {
  const ReceiptSaveResult({required this.filePath});

  final String filePath;
}

/// Downloads a server-generated receipt PDF from its (temporary) URL and hands
/// it to the OS share/save sheet so the user can save or forward it wherever
/// they choose.
///
/// SECURITY: the PDF contains personal/billing data, so it is staged in the
/// app's PRIVATE cache directory (not the world-readable public Downloads
/// folder) and deleted right after the share sheet closes. This keeps receipts
/// off shared storage where any other app could read them, and means the app
/// needs no external-storage permission.
///
/// The URL points at a third-party blob host (Azure), so it is fetched with a
/// dedicated [Dio] instance — NOT the app's [ApiClient] — to avoid attaching
/// the user's auth token and app headers to an external request.
class SessionReceiptDownloader {
  const SessionReceiptDownloader._();

  static const _timeout = Duration(seconds: 60);

  /// Fetches the PDF at [receiptUrl], stages it in app-private storage, opens
  /// the OS share/save sheet, then deletes the staged copy.
  ///
  /// Throws a [ReceiptDownloadException] (with a user-facing message) if the
  /// download, the disk write, or the share fails.
  static Future<ReceiptSaveResult> downloadAndShare({
    required String receiptUrl,
    required int sessionId,
  }) async {
    final bytes = await _fetchBytes(receiptUrl);
    final filename = 'HUBCO_Receipt_$sessionId.pdf';

    final saved = await _stageInPrivateCache(bytes, filename);

    try {
      // Hand the bytes to the system sheet. The user picks the destination
      // (Files/Downloads/share target); we never write to shared storage
      // ourselves.
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e, st) {
      AppLogger.d('[Receipt] share failed: $e\n$st');
      throw const ReceiptDownloadException(
        'The receipt could not be opened for sharing. Please try again.',
      );
    } finally {
      // Best-effort cleanup so the receipt doesn't linger in the cache.
      await _deleteQuietly(saved.filePath);
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
      AppLogger.d('[Receipt] fetch failed (${e.response?.statusCode}): ${e.message}');
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

  /// Writes [bytes] to the app's private cache directory (app-sandboxed on both
  /// Android and iOS — never world-readable).
  static Future<ReceiptSaveResult> _stageInPrivateCache(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      return ReceiptSaveResult(filePath: file.path);
    } catch (e, st) {
      AppLogger.d('[Receipt] stage failed: $e\n$st');
      throw const ReceiptDownloadException(
        'Could not prepare the receipt on your device. Please try again.',
      );
    }
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Non-fatal — the OS clears the cache directory eventually.
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
