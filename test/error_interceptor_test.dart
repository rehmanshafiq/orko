import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orko_hubco/core/network/interceptors/error_interceptor.dart';

/// Replies to every request with a fixed status and body.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body, {this.contentType = 'application/json'});

  final int status;
  final String body;
  final String contentType;

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
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<DioException> _fail(int status, Object? body, {String? contentType}) async {
  final dio = Dio()
    ..httpClientAdapter = _FakeAdapter(
      status,
      body is String ? body : jsonEncode(body),
      contentType: contentType ?? 'application/json',
    )
    ..interceptors.add(ErrorInterceptor());
  try {
    await dio.get('https://example.test/x');
  } on DioException catch (e) {
    return e;
  }
  fail('expected a DioException');
}

void main() {
  final reported = <String>[];
  setUp(() {
    reported.clear();
    ErrorInterceptor.onErrorMessage = reported.add;
  });
  tearDown(() => ErrorInterceptor.onErrorMessage = null);

  test('keeps the backend message', () async {
    final e = await _fail(422, {'message': 'Email already registered', 'x': 1});
    expect(e.response?.data['message'], 'Email already registered');
    expect(e.response?.data['x'], 1);
    expect(e.message, 'Email already registered');
  });

  test('derives the message from DRF field errors', () async {
    final e = await _fail(400, {
      'errors': {
        'phone_number': ['Enter a valid phone number.'],
      },
    });
    expect(e.response?.data['message'], 'Enter a valid phone number.');
  });

  test('derives the message from detail', () async {
    final e = await _fail(403, {'detail': 'Not allowed.'});
    expect(e.response?.data['message'], 'Not allowed.');
  });

  test('derives the message from field errors under body', () async {
    final e = await _fail(422, {
      'body': {
        'email': ['Enter a valid email address.'],
      },
    });
    expect(e.response?.data['message'], 'Enter a valid email address.');
  });

  test('falls back to the generic message', () async {
    final e = await _fail(503, <String, dynamic>{});
    expect(
      e.response?.data['message'],
      ErrorInterceptor.genericMessage,
    );
  });

  test('ignores HTML error pages', () async {
    final e = await _fail(
      502,
      '<html><body>Bad Gateway</body></html>',
      contentType: 'text/html',
    );
    expect(
      e.response?.data['message'],
      ErrorInterceptor.genericMessage,
    );
  });

  test('reports the message of an HTTP error', () async {
    await _fail(401, {'message': 'Please verify your phone number to continue.'});
    expect(reported, ['Please verify your phone number to continue.']);
  });

  test('reports a 200 whose body carries an error status', () async {
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter(
        200,
        jsonEncode({
          'status': 401,
          'message': 'Please verify your phone number to continue.',
          'body': {},
        }),
      )
      ..interceptors.add(ErrorInterceptor());
    await dio.get('https://example.test/x');
    expect(reported, ['Please verify your phone number to continue.']);
  });

  test('does not report a successful response', () async {
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter(200, jsonEncode({'status': 200}))
      ..interceptors.add(ErrorInterceptor());
    await dio.get('https://example.test/x');
    expect(reported, isEmpty);
  });

  test('a silent request is not reported', () async {
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter(500, jsonEncode({}))
      ..interceptors.add(ErrorInterceptor());
    await expectLater(
      dio.get(
        'https://example.test/x',
        options: Options(extra: {ErrorInterceptor.silentKey: true}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(reported, isEmpty);
  });
}
