import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:metronome_tap/app/controllers/history_controller.dart';
import 'package:metronome_tap/app/controllers/setting_controller.dart';
import 'package:metronome_tap/app/controllers/stats_controller.dart';
import 'package:metronome_tap/app/routes/app_pages.dart';

class SettingsPage extends GetView<SettingController> {
  const SettingsPage({super.key});

  static const Map<String, String> _languageOptions = {
    'en': 'English',
    'ko': '한굵어',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_loc('settings', 'Settings')),
        actions: [
          IconButton(
            tooltip: _loc('open_history', 'History'),
            icon: const Icon(Icons.history),
            onPressed: () => _openHistory(),
          ),
          IconButton(
            tooltip: _loc('open_stats', 'Stats'),
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _openStats(),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(
          () => ListView(
            padding: EdgeInsets.all(14.w),
            children: [
              _group(
                cs: cs,
                icon: Icons.settings,
                title: _loc('settings', 'Settings'),
                children: [
                  _buildSwitchTile(
                    icon: Icons.volume_up,
                    title: _loc('sound', 'Sound'),
                    subtitle: _loc('sound_desc', 'Play sound effects'),
                    value: controller.soundEnabled.value,
                    onChanged: controller.setSoundEnabled,
                  ),
                  _buildSwitchTile(
                    icon: Icons.vibration,
                    title: _loc('haptic', 'Haptic feedback'),
                    subtitle: _loc('haptic_desc', 'Vibrate for interactions'),
                    value: controller.hapticEnabled.value,
                    onChanged: controller.setHapticEnabled,
                  ),
                  _buildSwitchTile(
                    icon: Icons.privacy_tip,
                    title: _loc('ads_consent', 'Advertising consent'),
                    subtitle: _loc('ads_consent_desc', 'Use ad personalization preference'),
                    value: controller.adsConsent.value,
                    onChanged: controller.setAdsConsent,
                  ),
                  _sectionTitle(
                    title: _loc('language', 'Language'),
                    cs: cs,
                    icon: Icons.language,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                      child: Wrap(
                        spacing: 8.w,
                        children: _languageOptions.entries
                            .map(
                              (entry) => ChoiceChip(
                                label: Text(entry.value),
                                selected: controller.language.value == entry.key,
                                onSelected: (selected) {
                                  if (selected) {
                                    controller.setLanguage(entry.key);
                                  }
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _group(
                cs: cs,
                icon: Icons.workspace_premium,
                title: _loc('premium_title', 'Premium'),
                children: [
                  ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: Text(_loc('premium_title', 'Premium')), 
                    subtitle: Text(_loc('premium_subtitle', 'Unlock premium features and remove ads')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(Routes.PREMIUM),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _group(
                cs: cs,
                icon: Icons.delete_forever,
                title: _loc('clear_data', 'Clear local data'),
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(_loc('clear_data', 'Clear local data')),
                    subtitle: Text(_loc('clear_data_desc', 'Reset all local settings and usage records')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _clearData(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _group({
    required ColorScheme cs,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 12.w, 8.h),
            child: Row(
              children: [
                Icon(icon, size: 18.r, color: cs.primary),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required ColorScheme cs,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return ListTile(
      title: Row(
        children: [
          Icon(icon, color: cs.primary, size: 18.r),
          SizedBox(width: 8.w),
          Text(title),
        ],
      ),
      subtitle: child,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  void _openHistory() {
    controller.logEvent(
      'open_history',
      'settings',
      metadata: {'from': 'settings_page', 'action': 'button'},
    );
    Get.toNamed(Routes.HISTORY);
  }

  void _openStats() {
    controller.logEvent(
      'open_stats',
      'settings',
      metadata: {'from': 'settings_page', 'action': 'button'},
    );
    Get.toNamed(Routes.STATS);
  }

  Future<void> _clearData(BuildContext context) async {
    final theme = Get.theme.colorScheme;
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_loc('clear_data', 'Clear local data')),
        content: Text(_loc('clear_data_confirm', 'This removes all local settings and logs. Continue?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_loc('cancel', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_loc('confirm', 'Confirm')),
          ),
        ],
      ),
    );

    if (shouldClear != true) return;

    await controller.clearAppSettings();
    if (Get.isRegistered<HistoryController>()) {
      Get.find<HistoryController>().clearAll();
    }
    if (Get.isRegistered<StatsController>()) {
      Get.find<StatsController>().refresh();
    }

    controller.logEvent(
      'clear_data',
      'settings',
      metadata: {'action': 'clear_local_data'},
    );

    Get.snackbar(
      _loc('clear_data', 'Clear local data'),
      _loc('clear_data_complete', 'All local data has been removed.'),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: theme.surfaceContainerHigh,
      colorText: theme.onSurface,
    );
  }
}

String _loc(String key, String fallback) {
  final translated = key.tr;
  return translated == key ? fallback : translated;
}
