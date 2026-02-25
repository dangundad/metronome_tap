import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:metronome_tap/app/admob/ads_banner.dart';
import 'package:metronome_tap/app/admob/ads_helper.dart';
import 'package:metronome_tap/app/routes/app_pages.dart';
import 'package:metronome_tap/app/controllers/metronome_controller.dart';

class HomePage extends GetView<MetronomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withValues(alpha: 0.15),
              cs.surface,
              cs.secondaryContainer.withValues(alpha: 0.18),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                child: _TopBar(controller: controller),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                  child: Column(
                    children: [
                      _BpmDisplay(controller: controller),
                      SizedBox(height: 22.h),
                      _BeatIndicator(controller: controller),
                      SizedBox(height: 22.h),
                      _TimeSignatureSelector(controller: controller),
                      SizedBox(height: 16.h),
                      _BpmSlider(controller: controller),
                      SizedBox(height: 24.h),
                      _PlayButton(controller: controller),
                      SizedBox(height: 14.h),
                      _TapTempoButton(controller: controller),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
              Container(
                color: cs.surface.withValues(alpha: 0.92),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 12.w,
                      right: 12.w,
                      top: 8.h,
                      bottom: 10.h,
                    ),
                    child: BannerAdWidget(
                      adUnitId: AdHelper.bannerAdUnitId,
                      type: AdHelper.banner,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final MetronomeController controller;

  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.0),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutBack,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: Text('🎵', style: TextStyle(fontSize: 38.sp)),
              ),
              SizedBox(width: 10.w),
              Text(
                'app_name'.tr,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.menu_book_rounded),
          onPressed: () => Get.toNamed(Routes.GUIDE),
          tooltip: 'guide'.tr,
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => Get.toNamed(Routes.SETTINGS),
          tooltip: 'settings'.tr,
        ),
        Obx(
          () => IconButton(
            icon: Icon(
              controller.hapticEnabled.value
                  ? Icons.vibration_rounded
                  : Icons.phone_android_rounded,
              color:
                  controller.hapticEnabled.value ? cs.primary : cs.onSurfaceVariant,
            ),
            onPressed: controller.toggleHaptic,
            tooltip: 'haptic'.tr,
          ),
        ),
      ],
    );
  }
}

class _BpmDisplay extends StatelessWidget {
  final MetronomeController controller;

  const _BpmDisplay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(() {
        return Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                child: child,
              ),
              child: Text(
                '${controller.bpm.value}',
                key: ValueKey(controller.bpm.value),
                style: TextStyle(
                  fontSize: 78.sp,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                  height: 1,
                  letterSpacing: 1,
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'bpm'.tr,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              controller.tempoLabel,
              style: TextStyle(
                fontSize: 14.sp,
                color: cs.primary.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _BeatIndicator extends StatelessWidget {
  final MetronomeController controller;

  const _BeatIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final ts = controller.timeSignature.value;
      final active = controller.activeBeat.value;
      final isPlaying = controller.isPlaying.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(ts, (i) {
          final isActive = isPlaying && active == i;
          final isAccent = i == 0;
          final activeColor = isAccent ? cs.primary : cs.secondary;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: EdgeInsets.symmetric(horizontal: 6.w),
            width: isActive ? (isAccent ? 44.r : 34.r) : 24.r,
            height: isActive ? (isAccent ? 44.r : 34.r) : 24.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? activeColor
                  : isAccent
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.7),
                        blurRadius: isAccent ? 20 : 14,
                        spreadRadius: isAccent ? 5 : 3,
                      ),
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: isAccent ? 34 : 22,
                        spreadRadius: isAccent ? 7 : 4,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      );
    });
  }
}

class _TimeSignatureSelector extends StatelessWidget {
  final MetronomeController controller;

  const _TimeSignatureSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [2, 3, 4, 6].map((ts) {
          final isSelected = controller.timeSignature.value == ts;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: GestureDetector(
              onTap: () => controller.setTimeSignature(ts),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primaryContainer
                      : cs.surfaceContainerHigh.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isSelected ? cs.primary : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '$ts/4',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _BpmSlider extends StatelessWidget {
  final MetronomeController controller;

  const _BpmSlider({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(top: 4.h, left: 10.w, right: 10.w, bottom: 10.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Obx(() {
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5.h,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: cs.primary,
                inactiveTrackColor: cs.surfaceContainerHighest,
              ),
              child: Slider(
                value: controller.bpm.value.toDouble(),
                min: controller.minBpm.toDouble(),
                max: controller.maxBpm.toDouble(),
                divisions: controller.maxBpm - controller.minBpm,
                onChanged: (v) => controller.setBpm(v.round()),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${controller.minBpm}',
                    style: TextStyle(fontSize: 12.sp, color: cs.onSurfaceVariant),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded),
                        onPressed: () =>
                            controller.setBpm(controller.bpm.value - 1),
                        iconSize: 22.r,
                      ),
                      SizedBox(width: 4.w),
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: () =>
                            controller.setBpm(controller.bpm.value + 1),
                        iconSize: 22.r,
                      ),
                    ],
                  ),
                  Text(
                    '${controller.maxBpm}',
                    style: TextStyle(fontSize: 12.sp, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final MetronomeController controller;

  const _PlayButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final playing = controller.isPlaying.value;
      return GestureDetector(
        onTap: controller.toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 88.r,
          height: 88.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: playing ? cs.error : cs.primary,
            boxShadow: [
              BoxShadow(
                color: (playing ? cs.error : cs.primary).withValues(alpha: 0.4),
                blurRadius: playing ? 24 : 12,
                spreadRadius: playing ? 4 : 0,
              ),
            ],
          ),
          child: Icon(
            playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
            color: playing ? cs.onError : cs.onPrimary,
            size: 44.r,
          ),
        ),
      );
    });
  }
}

class _TapTempoButton extends StatefulWidget {
  final MetronomeController controller;

  const _TapTempoButton({required this.controller});

  @override
  State<_TapTempoButton> createState() => _TapTempoButtonState();
}

class _TapTempoButtonState extends State<_TapTempoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _pressCtrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressCtrl.reverse();
    widget.controller.onTap();
  }

  void _onTapCancel() {
    _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52.h,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.touch_app_rounded),
            label: Text(
              'tap_tempo'.tr,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
