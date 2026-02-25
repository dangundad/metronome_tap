import 'package:get/get.dart';

import 'package:metronome_tap/app/controllers/metronome_controller.dart';
import 'package:metronome_tap/app/controllers/setting_controller.dart';
import 'package:metronome_tap/app/services/hive_service.dart';

import 'package:metronome_tap/app/services/purchase_service.dart';
import 'package:metronome_tap/app/controllers/premium_controller.dart';

class AppBinding implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PurchaseService>()) {
      Get.put(PurchaseService(), permanent: true);
    }

    if (!Get.isRegistered<PremiumController>()) {
      Get.lazyPut(() => PremiumController());
    }

    if (!Get.isRegistered<HiveService>()) {
      Get.put(HiveService(), permanent: true);
    }

    if (!Get.isRegistered<SettingController>()) {
      Get.put(SettingController(), permanent: true);
    }

    if (!Get.isRegistered<MetronomeController>()) {
      Get.put(MetronomeController(), permanent: true);
    }
  }
}

