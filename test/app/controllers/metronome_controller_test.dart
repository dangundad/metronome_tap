// ignore_for_file: must_call_super

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:metronome_tap/app/controllers/metronome_controller.dart';
import 'package:metronome_tap/app/services/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const vibrationChannel = MethodChannel('vibration');

  setUp(() {
    Get.testMode = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(vibrationChannel, (call) async {
          if (call.method == 'hasVibrator') {
            return false;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(vibrationChannel, null);
    Get.reset();
  });

  test('closing flushes a pending debounced bpm save', () {
    final hive = _FakeHiveService();
    Get.put<HiveService>(hive);

    final controller = Get.put(MetronomeController());

    controller.setBpm(156);
    controller.onClose();

    expect(hive.data['metro_bpm'], 156);
  });
}

class _FakeHiveService extends HiveService {
  final Map<String, dynamic> data = <String, dynamic>{};

  @override
  T? getAppData<T>(String key, {T? defaultValue}) {
    return (data[key] ?? defaultValue) as T?;
  }

  @override
  Future<void> setAppData(String key, dynamic value) async {
    data[key] = value;
  }
}
