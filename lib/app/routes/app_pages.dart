// ================================================
// DangunDad Flutter App - app_pages.dart Template
// ================================================
// metronome_tap ?곸궡瑗????????
// mbti_pro ?熬곣뫁夷?筌먦끇????????リ옇?↑?(part ?????
// ignore_for_file: constant_identifier_names
// import 'package:metronome_tap/app/pages/settings/settings_page.dart';

import 'package:get/get.dart';
import 'package:metronome_tap/app/bindings/app_binding.dart';
import 'package:metronome_tap/app/pages/history/history_page.dart';
import 'package:metronome_tap/app/pages/home/home_page.dart';
import 'package:metronome_tap/app/pages/guide/guide_page.dart';
import 'package:metronome_tap/app/pages/settings/settings_page.dart';
import 'package:metronome_tap/app/pages/stats/stats_page.dart';
import 'package:metronome_tap/app/pages/premium/premium_page.dart';
import 'package:metronome_tap/app/pages/premium/premium_binding.dart';
part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomePage(),
      binding: AppBinding(),
    ),
    // GetPage(
    //   name: _Paths.SETTINGS,
    //   page: () => const SettingsPage(),
    //   binding: BindingsBuilder(() {
    //     Get.lazyPut(() => SettingController());
    //   }),
    // ),
    // ---- ?繹먮굟????瑜곷턄嶺뚯솘? ?怨뺣뼺? ----
    GetPage(name: _Paths.SETTINGS, page: () => const SettingsPage()),
    GetPage(name: _Paths.HISTORY, page: () => const HistoryPage()),
    GetPage(name: _Paths.STATS, page: () => const StatsPage()),
    GetPage(name: _Paths.GUIDE, page: () => const GuidePage()),
    GetPage(
      name: _Paths.PREMIUM,
      page: () => const PremiumPage(),
      binding: PremiumBinding(),
    ),
];
}

