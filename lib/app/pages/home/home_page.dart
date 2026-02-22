import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:metronome_tap/app/admob/ads_banner.dart';
import 'package:metronome_tap/app/admob/ads_helper.dart';
import 'package:metronome_tap/app/controllers/metronome_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MetronomeController>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('app_name'.tr),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                controller.hapticEnabled.value
                    ? Icons.vibration_rounded
                    : Icons.phone_android_rounded,
                color: controller.hapticEnabled.value
                    ? cs.primary
                    : cs.onSurfaceVariant,
              ),
              onPressed: controller.toggleHaptic,
              tooltip: 'haptic'.tr,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 24.h),
                    _BpmDisplay(controller: controller),
                    SizedBox(height: 28.h),
                    _BeatIndicator(controller: controller),
                    SizedBox(height: 28.h),
                    _TimeSignatureSelector(controller: controller),
                    SizedBox(height: 24.h),
                    _BpmSlider(controller: controller),
                    SizedBox(height: 32.h),
                    _PlayButton(controller: controller),
                    SizedBox(height: 20.h),
                    _TapTempoButton(controller: controller),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
            BannerAdWidget(
              adUnitId: AdHelper.bannerAdUnitId,
              type: AdHelper.banner,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BPM Display (with AnimatedSwitcher scale on change) ──
class _BpmDisplay extends StatelessWidget {
  final MetronomeController controller;

  const _BpmDisplay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
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
                fontSize: 80.sp,
                fontWeight: FontWeight.w900,
                color: cs.primary,
                height: 1,
              ),
            ),
          ),
          Text(
            'BPM',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 4,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            controller.tempoLabel,
            style: TextStyle(
              fontSize: 14.sp,
              color: cs.primary.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    });
  }
}

// ─── Beat Indicator (enhanced glow on active) ────────────
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
            duration: const Duration(milliseconds: 80),
            margin: EdgeInsets.symmetric(horizontal: 6.w),
            width: isActive ? (isAccent ? 44.r : 34.r) : 24.r,
            height: isActive ? (isAccent ? 44.r : 34.r) : 24.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? activeColor
                  : isAccent
                      ? cs.primaryContainer
                      : cs.surfaceContainerHigh,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.7),
                        blurRadius: isAccent ? 20 : 14,
                        spreadRadius: isAccent ? 5 : 3,
                      ),
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: isAccent ? 36 : 24,
                        spreadRadius: isAccent ? 8 : 5,
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

// ─── Time Signature Selector ─────────────────────────────
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
                duration: const Duration(milliseconds: 150),
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primaryContainer
                      : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? cs.primary : Colors.transparent,
                    width: 2,
                  ),
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

// ─── BPM Slider ─────────────────────────────────────────
class _BpmSlider extends StatelessWidget {
  final MetronomeController controller;

  const _BpmSlider({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      return Column(
        children: [
          Slider(
            value: controller.bpm.value.toDouble(),
            min: controller.minBpm.toDouble(),
            max: controller.maxBpm.toDouble(),
            divisions: controller.maxBpm - controller.minBpm,
            onChanged: (v) => controller.setBpm(v.round()),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${controller.minBpm}',
                  style:
                      TextStyle(fontSize: 12.sp, color: cs.onSurfaceVariant),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded),
                      onPressed: () =>
                          controller.setBpm(controller.bpm.value - 1),
                      iconSize: 20.r,
                    ),
                    SizedBox(width: 4.w),
                    IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () =>
                          controller.setBpm(controller.bpm.value + 1),
                      iconSize: 20.r,
                    ),
                  ],
                ),
                Text(
                  '${controller.maxBpm}',
                  style:
                      TextStyle(fontSize: 12.sp, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ─── Play/Stop Button ────────────────────────────────────
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
          duration: const Duration(milliseconds: 200),
          width: 88.r,
          height: 88.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: playing ? cs.error : cs.primary,
            boxShadow: [
              BoxShadow(
                color: (playing ? cs.error : cs.primary)
                    .withValues(alpha: 0.4),
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

// ─── Tap Tempo Button (with press scale feedback) ────────
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
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52.h,
          child: OutlinedButton.icon(
            onPressed: null, // handled by GestureDetector
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
