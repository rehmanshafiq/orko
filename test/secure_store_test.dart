import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/services/secure_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('drops a Keychain token left by a previous install', () async {
    final dir = await Directory.systemTemp.createTemp('secure_store_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => dir.path,
    );
    // Reinstall: Keychain still holds the old token, GetStorage box is empty.
    FlutterSecureStorage.setMockInitialValues({
      StorageConstants.accessToken: 'stale',
    });
    await GetStorage.init();

    await SecureStore.instance.init();

    expect(SecureStore.instance.read(StorageConstants.accessToken), isNull);
    expect(
      await const FlutterSecureStorage()
          .read(key: StorageConstants.accessToken),
      isNull,
    );
  });
}
