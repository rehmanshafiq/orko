import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orko_hubco/core/network/interceptors/app_update_interceptor.dart';

/// Replies to every request with a fixed status and JSON body.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AppUpdateInterceptor.parseLevel', () {
    test('accepts ints, numeric strings and whole doubles', () {
      expect(AppUpdateInterceptor.parseLevel({'update_available': 0}), 0);
      expect(AppUpdateInterceptor.parseLevel({'update_available': 2}), 2);
      expect(AppUpdateInterceptor.parseLevel({'update_available': '1'}), 1);
      expect(AppUpdateInterceptor.parseLevel({'update_available': ' 2 '}), 2);
      expect(AppUpdateInterceptor.parseLevel({'update_available': 1.0}), 1);
    });

    test('ignores missing, null, invalid and out-of-range values', () {
      expect(AppUpdateInterceptor.parseLevel({}), isNull);
      expect(AppUpdateInterceptor.parseLevel({'update_available': null}),
          isNull);
      expect(AppUpdateInterceptor.parseLevel({'update_available': 'yes'}),
          isNull);
      expect(AppUpdateInterceptor.parseLevel({'update_available': true}),
          isNull);
      expect(AppUpdateInterceptor.parseLevel({'update_available': 1.5}),
          isNull);
      expect(AppUpdateInterceptor.parseLevel({'update_available': 3}), isNull);
      expect(AppUpdateInterceptor.parseLevel({'update_available': -1}),
          isNull);
      expect(AppUpdateInterceptor.parseLevel(null), isNull);
      expect(AppUpdateInterceptor.parseLevel([1]), isNull);
      expect(AppUpdateInterceptor.parseLevel('<html>'), isNull);
    });

    test('reads an undecoded JSON string body', () {
      expect(
        AppUpdateInterceptor.parseLevel('{"update_available": 1}'),
        1,
      );
    });
  });

  group('AppUpdateInterceptor in a Dio chain', () {
    final reported = <int>[];

    setUp(() {
      reported.clear();
      AppUpdateInterceptor.onUpdateLevel = reported.add;
    });

    tearDown(() => AppUpdateInterceptor.onUpdateLevel = null);

    Dio dioReplying(int status, String body) {
      return Dio()
        ..httpClientAdapter = _FakeAdapter(status, body)
        ..interceptors.add(AppUpdateInterceptor());
    }

    test('reports the level from a successful response', () async {
      final dio = dioReplying(
        200,
        '{"status": 200, "message": "ok", "body": {}, "exception": null, '
            '"update_available": 1}',
      );
      await dio.get('https://example.test/');
      expect(reported, [1]);
    });

    test('reports the level from an error response (401)', () async {
      final dio = dioReplying(
        401,
        '{"status": 401, "message": "Unauthorized", "update_available": 2}',
      );
      await expectLater(dio.get('https://example.test/'),
          throwsA(isA<DioException>()));
      expect(reported, [2]);
    });

    test('reports nothing when the flag is absent', () async {
      final dio = dioReplying(200, '{"status": 200, "body": {}}');
      await dio.get('https://example.test/');
      expect(reported, isEmpty);
    });
  });
}
