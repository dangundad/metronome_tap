import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:metronome_tap/app/admob/ads_banner.dart';
import 'package:metronome_tap/app/admob/ads_helper.dart';
import 'package:metronome_tap/app/routes/app_pages.dart';
import 'package:metronome_tap/app/controllers/metronome_controller.dart';

class HomePage extends GetView<MetronomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext _) {
    final cs = Get.theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.0),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutBack,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Text('🎵', style: TextStyle(fontSize: 28.sp)),
              ),
              SizedBox(width: 8.w),
              Text(
                'app_name'.tr,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        actions: [
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
                color: controller.hapticEnabled.value
                    ? cs.primary
                    : cs.onSurfaceVariant,
              ),
              onPressed: controller.toggleHaptic,
              tooltip: 'haptic'.tr,
            ),
          ),
          SizedBox(width: 4.w),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: ColoredBox(
            color: cs.primary,
            child: const SizedBox(height: 3),
          ),
        ),
      ),
      body: ColoredBox(
        color: cs.surface,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    children: [
                      _BpmDisplay(controller: controller),
                      SizedBox(height: 22.h),
                      _BeatIndicator(controller: controller),
                      SizedBox(height: 20.h),
                      _TimeSignatureCard(controller: controller),
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

// ─── BPM Display with vertical drag gesture ─────────────
class _BpmDisplay extends StatefulWidget {
  final MetronomeController controller;

  const _BpmDisplay({required this.controller});

  @override
  State<_BpmDisplay> createState() => _BpmDisplayState();
}

class _BpmDisplayState extends State<_BpmDisplay> {
  double _dragAccumulator = 0;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragAccumulator -= details.primaryDelta ?? 0;
    while (_dragAccumulator >= 10) {
      widget.controller.setBpm(widget.controller.bpm.value + 1);
      _dragAccumulator -= 10;
    }
    while (_dragAccumulator <= -10) {
      widget.controller.setBpm(widget.controller.bpm.value - 1);
      _dragAccumulator += 10;
    }
  }

  void _onVerticalDragEnd(DragEndDetails _) {
    _dragAccumulator = 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Obx(() {
        final isPlaying = widget.controller.isPlaying.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
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
                    : cs.primary.withValues(alpha: 0.12),
                blurRadius: isPlaying ? 28 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // BPM number
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutBack,
                  ),
                  child: child,
                ),
                child: Text(
                  '${widget.controller.bpm.value}',
                  key: ValueKey(widget.controller.bpm.value),
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
                      ? cs.primary.withValues(alpha: 0.18)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  widget.controller.tempoLabel,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isPlaying ? cs.primary : cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              // Drag hint
              Text(
                'drag_bpm_hint'.tr,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Beat Indicator with accent control and sub-beat dots ──
class _BeatIndicator extends StatelessWidget {
  final MetronomeController controller;

  const _BeatIndicator({required this.controller});

  @override
  Widget build(BuildContext _) {
    final cs = Get.theme.colorScheme;
    return Obx(() {
      final ts = controller.timeSignature.value;
      final active = controller.activeBeat.value;
      final activeSub = controller.activeSubBeat.value;
      final isPlaying = controller.isPlaying.value;
      final sub = controller.subdivision.value;

      // Adaptive sizing based on total elements
      final totalElements = ts + (sub > 1 ? ts * (sub - 1) : 0);
      final mainSize = totalElements > 14 ? 28.r : 36.r;
      final activeSize = totalElements > 14 ? 32.r : 42.r;
      final numFontSize = totalElements > 14 ? 11.sp : 14.sp;

      final children = <Widget>[];

      for (int i = 0; i < ts; i++) {
        final isActive = isPlaying && active == i && activeSub == 0;
        final accent = i < controller.accents.length
            ? controller.accents[i]
            : BeatAccent.normal;

        // Main beat dot (tappable to toggle accent)
        children.add(
          GestureDetector(
            onTap: () {
              if (controller.hapticEnabled.value) {
                HapticFeedback.lightImpact();
              }
              controller.toggleAccent(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: isActive ? activeSize : mainSize,
              height: isActive ? activeSize : mainSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _beatColor(accent, isActive, cs),
                border: accent == BeatAccent.normal && !isActive
                    ? Border.all(color: cs.secondary, width: 2)
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _beatGlowColor(accent, cs),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: accent == BeatAccent.mute
                    ? Icon(
                        Icons.close_rounded,
                        size: totalElements > 14 ? 14.r : 16.r,
                        color: cs.onSurfaceVariant,
                      )
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: numFontSize,
                          fontWeight: FontWeight.w700,
                          color: isActive || accent == BeatAccent.strong
                              ? cs.onPrimary
                              : cs.onSurface,
                        ),
                      ),
              ),
            ),
          ),
        );

        // Sub-beat dots after each beat
        if (sub > 1) {
          for (int s = 1; s < sub; s++) {
            final isSubActive = isPlaying && active == i && activeSub == s;
            children.add(
              AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                margin: EdgeInsets.symmetric(horizontal: 1.w),
                width: isSubActive ? 10.r : 6.r,
                height: isSubActive ? 10.r : 6.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSubActive
                      ? cs.tertiary
                      : cs.onSurfaceVariant.withValues(alpha: 0.25),
                  boxShadow: isSubActive
                      ? [
                          BoxShadow(
                            color: cs.tertiary.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }
        }
      }

      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6.w,
        runSpacing: 8.h,
        children: children,
      );
    });
  }

  Color _beatColor(BeatAccent accent, bool isActive, ColorScheme cs) {
    if (isActive) {
      return accent == BeatAccent.strong ? cs.primary : cs.secondary;
    }
    switch (accent) {
      case BeatAccent.strong:
        return cs.primaryContainer;
      case BeatAccent.normal:
        return Colors.transparent;
      case BeatAccent.mute:
        return cs.surfaceContainerHighest;
    }
  }

  Color _beatGlowColor(BeatAccent accent, ColorScheme cs) {
    switch (accent) {
      case BeatAccent.strong:
        return cs.primary.withValues(alpha: 0.6);
      case BeatAccent.normal:
        return cs.secondary.withValues(alpha: 0.5);
      case BeatAccent.mute:
        return Colors.transparent;
    }
  }
}

// ─── Time Signature + Subdivision Card ──────────────────
class _TimeSignatureCard extends StatelessWidget {
  final MetronomeController controller;

  const _TimeSignatureCard({required this.controller});

  @override
  Widget build(BuildContext _) {
    final cs = Get.theme.colorScheme;
    return Obx(
      () => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time signature header
            Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.music,
                      size: 20.r,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'beat_pattern'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      controller.tsLabel,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _TimeSignatureSelector(controller: controller),
            SizedBox(height: 16.h),
            // Divider
            Container(
              height: 1,
              color: cs.onPrimaryContainer.withValues(alpha: 0.12),
            ),
            SizedBox(height: 14.h),
            // Subdivision header
            Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      size: 20.r,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'subdivision'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _subdivisionLabel(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _SubdivisionSelector(controller: controller),
          ],
        ),
      ),
    );
  }

  String _subdivisionLabel() {
    return switch (controller.subdivision.value) {
      2 => '♪♪',
      3 => '♪♪♪',
      4 => '♬♬',
      _ => '♩',
    };
  }
}

// Time Signature selector with 6 options including 5/4 and 7/8
class _TimeSignatureSelector extends StatelessWidget {
  final MetronomeController controller;

  const _TimeSignatureSelector({required this.controller});

  @override
  Widget build(BuildContext _) {
    final cs = Get.theme.colorScheme;
    return Obx(() {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.w,
        runSpacing: 8.h,
        children: MetronomeController.tsOptions.map((ts) {
          final beats = ts.$1;
          final denom = ts.$2;
          final isSelected =
              controller.timeSignature.value == beats &&
              controller.timeSigDenom.value == denom;
          return GestureDetector(
            onTap: () => controller.setTimeSignature(beats, denom),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary
                    : cs.surfaceContainerHigh.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isSelected ? cs.primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.30),
                          blurRadius: 12,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '$beats/$denom',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

// Subdivision selector: quarter, eighth, triplet, sixteenth
class _SubdivisionSelector extends StatelessWidget {
  final MetronomeController controller;

  const _SubdivisionSelector({required this.controller});

  static const _labels = ['♩', '♪♪', '♪♪♪', '♬♬'];
  static const _values = [1, 2, 3, 4];

  @override
  Widget build(BuildContext _) {
    final cs = Get.theme.colorScheme;
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          final isSelected = controller.subdivision.value == _values[i];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: GestureDetector(
              onTap: () => controller.setSubdivision(_values[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.secondary
                      : cs.surfaceContainerHigh.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? cs.secondary : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cs.secondary.withValues(alpha: 0.30),
                            blurRadius: 10,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? cs.onSecondary : cs.onSurface,
                  ),
                ),
              ),
            ),
          );
        }),
      );
    });
  }
}

class _BpmSlider extends StatelessWidget {
  final MetronomeController controller;

  const _BpmSlider({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Get.theme.colorScheme;
    return Container(
      padding: EdgeInsets.only(top: 4.h, left: 10.w, right: 10.w, bottom: 10.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
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
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      _BpmStepButton(
                        icon: Icons.remove_rounded,
                        cs: cs,
                        onTap: () =>
                            controller.setBpm(controller.bpm.value - 1),
                      ),
                      SizedBox(width: 4.w),
                      _BpmStepButton(
                        icon: Icons.add_rounded,
                        cs: cs,
                        onTap: () =>
                            controller.setBpm(controller.bpm.value + 1),
                      ),
                    ],
                  ),
                  Text(
                    '${controller.maxBpm}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: cs.onSurfaceVariant,
                    ),
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
  Widget build(BuildContext _) {
    final cs = Get.theme.colorScheme;
    return Obx(() {
      final playing = controller.isPlaying.value;
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: playing ? cs.error : cs.primary,
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
                    playing ? LucideIcons.square : LucideIcons.play,
                    size: 22.r,
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
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
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
    if (widget.controller.hapticEnabled.value) {
      HapticFeedback.lightImpact();
    }
    widget.controller.onTap();
  }

  void _onTapCancel() {
    _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext _) {
    final cs = Get.theme.colorScheme;
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
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
                Icon(LucideIcons.pointer, size: 20.r, color: cs.primary),
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

// Enhanced tap counter with live BPM and confidence indicator
class _TapCounterLabel extends StatelessWidget {
  final MetronomeController controller;

  const _TapCounterLabel({required this.controller});

  @override
  Widget build(BuildContext _) {
    final cs = Get.theme.colorScheme;
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
      if (count < 2) {
        return Text(
          'tap_count_one'.tr,
          style: TextStyle(
            fontSize: 12.sp,
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        );
      }
      // Show detected BPM + tap count + confidence dots
      final confidence = controller.tapConfidence;
      final filledDots = (confidence * 4).round().clamp(1, 4);
      final dots = List.generate(4, (i) => i < filledDots ? '●' : '○').join();

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Text(
          '${controller.bpm.value} BPM · $count${'taps_unit'.tr} · $dots',
          key: ValueKey('$count-${controller.bpm.value}'),
          style: TextStyle(
            fontSize: 13.sp,
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    });
  }
}
