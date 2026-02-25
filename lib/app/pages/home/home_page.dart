import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                      SizedBox(height: 8.h),
                      _TapCounterLabel(controller: controller),
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
              controller.isSoundEnabled.value
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: controller.isSoundEnabled.value
                  ? cs.primary
                  : cs.onSurfaceVariant,
            ),
            onPressed: controller.toggleSound,
            tooltip: 'sound'.tr,
          ),
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

// BPM Display — gradient card with enhanced typography
class _BpmDisplay extends StatelessWidget {
  final MetronomeController controller;

  const _BpmDisplay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final isPlaying = controller.isPlaying.value;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPlaying
                ? [
                    cs.primary.withValues(alpha: 0.22),
                    cs.primaryContainer,
                  ]
                : [
                    cs.surfaceContainerLow,
                    cs.surface,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isPlaying
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outline.withValues(alpha: 0.15),
            width: isPlaying ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPlaying
                  ? cs.primary.withValues(alpha: 0.28)
                  : Colors.black.withValues(alpha: 0.10),
              blurRadius: isPlaying ? 28 : 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // BPM number
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
                  fontSize: 86.sp,
                  fontWeight: FontWeight.w900,
                  color: isPlaying ? cs.primary : cs.onSurface,
                  height: 1,
                  letterSpacing: 1,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            // BPM label with decorative line
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24.w,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(1.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'bpm'.tr,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 24.w,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(1.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // Tempo label badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: isPlaying
                    ? cs.primary.withValues(alpha: 0.15)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                controller.tempoLabel,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isPlaying ? cs.primary : cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    });
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
                      _BpmStepButton(
                        icon: Icons.remove_rounded,
                        cs: cs,
                        onTap: () => controller.setBpm(controller.bpm.value - 1),
                      ),
                      SizedBox(width: 4.w),
                      _BpmStepButton(
                        icon: Icons.add_rounded,
                        cs: cs,
                        onTap: () => controller.setBpm(controller.bpm.value + 1),
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

// BPM step button with subtle styled container
class _BpmStepButton extends StatelessWidget {
  final IconData icon;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _BpmStepButton({
    required this.icon,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Icon(icon, size: 18.r, color: cs.onPrimaryContainer),
        ),
      ),
    );
  }
}

// Play button — gradient CTA
class _PlayButton extends StatelessWidget {
  final MetronomeController controller;

  const _PlayButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final playing = controller.isPlaying.value;
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: playing
              ? LinearGradient(
                  colors: [cs.error, cs.errorContainer],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: (playing ? cs.error : cs.primary).withValues(alpha: 0.40),
              blurRadius: playing ? 24 : 14,
              spreadRadius: playing ? 2 : 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: controller.toggle,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 26.r,
                    color: playing ? cs.onError : cs.onPrimary,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    playing ? 'stop'.tr : 'play'.tr,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: playing ? cs.onError : cs.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
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
    HapticFeedback.selectionClick();
    widget.controller.onTap();
  }

  void _onTapCancel() {
    _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 20.r,
                  color: cs.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  'tap_tempo'.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Tap counter label shown below the Tap Tempo button
class _TapCounterLabel extends StatelessWidget {
  final MetronomeController controller;

  const _TapCounterLabel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final count = controller.tapCount.value;
      if (count == 0) {
        return Text(
          'tap_for_bpm'.tr,
          style: TextStyle(
            fontSize: 12.sp,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        );
      }
      final label = count < 2
          ? 'tap_count_one'.tr
          : 'tap_count_many'.trParams({'count': '$count'});
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Text(
          label,
          key: ValueKey(count),
          style: TextStyle(
            fontSize: 12.sp,
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    });
  }
}
