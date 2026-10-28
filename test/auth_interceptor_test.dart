import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/network/interceptors/auth_interceptor.dart';
import 'package:orko_hubco/core/services/secure_store.dart';

/// Answers every request with [statusCode], after running [beforeRespond].
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode, {this.beforeRespond});

  final int statusCode;
  final Future<void> Function()? beforeRespond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await beforeRespond?.call();
    return ResponseBody.fromString('{}', statusCode, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int expiredCalls;
  late Completer<void> expiry;

  Dio buildDio(int statusCode, {Future<void> Function()? beforeRespond}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    dio.httpClientAdapter =
        _StatusAdapter(statusCode, beforeRespond: beforeRespond);
    dio.interceptors.add(AuthInterceptor(onSessionExpired: () {
      expiredCalls++;
      return expiry.future;
    }));
    return dio;
  }

  Future<void> swallow(Future<Response> request) =>
      request.then((_) {}, onError: (_) {});

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SecureStore.instance.clear();
    expiredCalls = 0;
    expiry = Completer<void>();
  });

  test('401 on a request carrying the current token expires the session',
      () async {
    await SecureStore.instance.write(StorageConstants.accessToken, 'tok-1');
    final dio = buildDio(401);

    await expectLater(
      dio.get('/me'),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'status', 401)),
    );
    expect(expiredCalls, 1);
  });

  test('concurrent 401s trigger a single logout', () async {
    await SecureStore.instance.write(StorageConstants.accessToken, 'tok-1');
    final dio = buildDio(401);

    await Future.wait([swallow(dio.get('/a')), swallow(dio.get('/b'))]);
    expect(expiredCalls, 1);

    expiry.complete();
  });

  test('401 without a token (login / guest) does not log out', () async {
    final dio = buildDio(401);

    await swallow(dio.post('/login'));
    expect(expiredCalls, 0);
  });

  test('stale 401 for a token already replaced does not log out', () async {
    await SecureStore.instance.write(StorageConstants.accessToken, 'old');
    final dio = buildDio(401, beforeRespond: () async {
      await SecureStore.instance.write(StorageConstants.accessToken, 'new');
    });

    await swallow(dio.get('/me'));
    expect(expiredCalls, 0);
  });

  test('non-401 errors do not log out', () async {
    await SecureStore.instance.write(StorageConstants.accessToken, 'tok-1');
    final dio = buildDio(403);

    await swallow(dio.get('/me'));
    expect(expiredCalls, 0);
  });
}
