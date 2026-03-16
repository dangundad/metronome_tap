import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

import 'package:metronome_tap/app/controllers/setting_controller.dart';
import 'package:metronome_tap/app/services/hive_service.dart';

class MetronomeController extends GetxController {
  static MetronomeController get to => Get.find();

  static const int _minBpm = 40;
  static const int _maxBpm = 280;

  // Hive keys
  static const _bpmKey = 'metro_bpm';
  static const _tsKey = 'metro_time_sig';
  static const _hapticKey = 'metro_haptic';
  static const _soundKey = 'metro_sound';

  // State
  final bpm = 120.obs;
  final timeSignature = 4.obs; // beats per measure
  final isPlaying = false.obs;
  final activeBeat = (-1).obs; // -1 = stopped
  final hapticEnabled = true.obs;
  final isSoundEnabled = true.obs;

  bool _hasVibrator = false;

  // Cached setting references (avoid repeated Get.isRegistered on hot path)
  SettingController? _settingCtrl;

  // Tap tempo
  final _tapTimes = <DateTime>[];
  final tapCount = 0.obs; // visible tap counter
  Timer? _tapResetTimer;

  // Debounce timer for saving BPM during slider drag
  Timer? _saveBpmDebounce;

  // Absolute-time beat scheduler (drift-free)
  Timer? _beatTimer;
  DateTime? _nextBeatTime; // wall-clock time of next scheduled beat

  @override
  void onInit() {
    super.onInit();
    _initVibrator();
    _cacheSettingController();
    _loadPrefs();
  }

  @override
  void onClose() {
    _beatTimer?.cancel();
    _tapResetTimer?.cancel();
    _saveBpmDebounce?.cancel();
    super.onClose();
  }

  /// Initialize vibrator check once and await it properly.
  Future<void> _initVibrator() async {
    final result = await Vibration.hasVibrator();
    _hasVibrator = result;
  }

  /// Cache the SettingController reference so _fireBeat doesn't need
  /// Get.isRegistered on every tick.
  void _cacheSettingController() {
    if (Get.isRegistered<SettingController>()) {
      _settingCtrl = SettingController.to;
    }
  }

  void _loadPrefs() {
    bpm.value = HiveService.to.getAppData<int>(_bpmKey) ?? 120;
    timeSignature.value = HiveService.to.getAppData<int>(_tsKey) ?? 4;
    hapticEnabled.value =
        HiveService.to.getAppData<bool>(_hapticKey) ?? true;
    isSoundEnabled.value =
        HiveService.to.getAppData<bool>(_soundKey) ?? true;

    // Sync from SettingController if available
    if (_settingCtrl != null) {
      hapticEnabled.value = _settingCtrl!.hapticEnabled.value;
      isSoundEnabled.value = _settingCtrl!.soundEnabled.value;
    }
  }

  void _savePrefs() {
    HiveService.to.setAppData(_bpmKey, bpm.value);
    HiveService.to.setAppData(_tsKey, timeSignature.value);
    HiveService.to.setAppData(_hapticKey, hapticEnabled.value);
    HiveService.to.setAppData(_soundKey, isSoundEnabled.value);
  }

  /// Save BPM with debounce to avoid excessive Hive writes during slider drag.
  void _saveBpmDebounced() {
    _saveBpmDebounce?.cancel();
    _saveBpmDebounce = Timer(const Duration(milliseconds: 500), () {
      HiveService.to.setAppData(_bpmKey, bpm.value);
    });
  }

  // ─── Controls ─────────────────────────────────────────
  void toggle() => isPlaying.value ? stop() : start();

  void start() {
    // Re-cache in case SettingController was registered after onInit
    _cacheSettingController();
    isPlaying.value = true;
    activeBeat.value = -1;
    _startScheduler();
  }

  void stop() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _nextBeatTime = null;
    isPlaying.value = false;
    activeBeat.value = -1;
  }

  void setBpm(int value) {
    bpm.value = value.clamp(_minBpm, _maxBpm);
    if (isPlaying.value) {
      // Reschedule without firing an extra immediate beat.
      _rescheduleFromNow();
    }
    // Debounced save during slider interaction
    _saveBpmDebounced();
  }

  void setTimeSignature(int beats) {
    timeSignature.value = beats;
    // Reset beat counter so the next beat is beat 0 (downbeat).
    activeBeat.value = -1;
    if (isPlaying.value) {
      _rescheduleFromNow();
    }
    _savePrefs();
  }

  void toggleHaptic() {
    hapticEnabled.value = !hapticEnabled.value;
    _savePrefs();
  }

  void toggleSound() {
    isSoundEnabled.value = !isSoundEnabled.value;
    _savePrefs();
  }

  // ─── Beat scheduling (drift-free) ─────────────────────
  //
  // Strategy: fire the first beat immediately and track the absolute wall-clock
  // time that each subsequent beat SHOULD occur. Each timer fires slightly early
  // by scheduling for (nextBeatTime - now); if Dart's event loop delivers it a
  // few ms late, the next interval is shortened by that overshoot so the beat
  // grid stays anchored to real time rather than drifting forward.

  void _startScheduler() {
    _fireBeat(); // beat 0 fires immediately
    _nextBeatTime =
        DateTime.now().add(_intervalDuration);
    _scheduleNextTimer();
  }

  /// Reschedule without firing an extra beat (used when BPM/TS changes mid-play).
  void _rescheduleFromNow() {
    _beatTimer?.cancel();
    _beatTimer = null;
    // Place the next beat one full interval from now.
    _nextBeatTime =
        DateTime.now().add(_intervalDuration);
    _scheduleNextTimer();
  }

  void _scheduleNextTimer() {
    final delay = _nextBeatTime!.difference(DateTime.now());
    // Guard against a negative delay (event loop was very late).
    final safeDelay = delay.isNegative ? Duration.zero : delay;
    _beatTimer = Timer(safeDelay, _onTimerFired);
  }

  void _onTimerFired() {
    if (!isPlaying.value) return;
    _fireBeat();

    // Advance the absolute target by exactly one interval regardless of when
    // this callback actually ran -- this prevents cumulative drift.
    _nextBeatTime = _nextBeatTime!.add(_intervalDuration);
    _scheduleNextTimer();
  }

  Duration get _intervalDuration =>
      Duration(microseconds: (60000000 / bpm.value).round());

  void _fireBeat() {
    final ts = timeSignature.value;
    final next = (activeBeat.value + 1) % ts;
    activeBeat.value = next;

    // Use cached controller reference instead of Get.isRegistered per tick
    final soundOn = _settingCtrl?.soundEnabled.value ?? isSoundEnabled.value;
    final hapticOn = _settingCtrl?.hapticEnabled.value ?? hapticEnabled.value;

    if (soundOn) {
      SystemSound.play(SystemSoundType.click);
    }

    if (hapticOn && _hasVibrator) {
      if (next == 0) {
        Vibration.vibrate(duration: 200);
      } else {
        Vibration.vibrate(duration: 100);
      }
    }
  }

  // ─── Tap tempo ────────────────────────────────────────
  void onTap() {
    final now = DateTime.now();

    // Reset tap history after 3 seconds of silence
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 3), () {
      _tapTimes.clear();
      tapCount.value = 0;
    });

    _tapTimes.add(now);

    // Keep only last 8 taps (trim before updating tapCount so the
    // counter always reflects the number of intervals being averaged)
    if (_tapTimes.length > 8) _tapTimes.removeAt(0);

    tapCount.value = _tapTimes.length;

    if (_tapTimes.length >= 2) {
      // Compute intervals in milliseconds
      final intervals = <int>[];
      for (int i = 1; i < _tapTimes.length; i++) {
        intervals.add(
            _tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds);
      }

      // Filter outliers: discard intervals that deviate more than 50%
      // from the median to avoid erratic taps skewing the result.
      final filteredIntervals = _filterOutliers(intervals);

      if (filteredIntervals.isNotEmpty) {
        final avgInterval =
            filteredIntervals.reduce((a, b) => a + b) / filteredIntervals.length;
        if (avgInterval > 0) {
          final newBpm =
              (60000 / avgInterval).round().clamp(_minBpm, _maxBpm);
          setBpm(newBpm);
        }
      }
    }
  }

  /// Filter outlier intervals using median absolute deviation.
  /// Discard intervals that deviate more than 50% from the median.
  List<int> _filterOutliers(List<int> intervals) {
    if (intervals.length < 3) return intervals;

    final sorted = List<int>.from(intervals)..sort();
    final median = sorted[sorted.length ~/ 2];

    // Threshold: 50% of median
    final threshold = median * 0.5;

    return intervals
        .where((iv) => (iv - median).abs() <= threshold)
        .toList();
  }

  // ─── BPM helpers ──────────────────────────────────────
  int get minBpm => _minBpm;
  int get maxBpm => _maxBpm;

  String get tempoLabel {
    final b = bpm.value;
    if (b < 60) return 'Largo';
    if (b < 66) return 'Larghetto';
    if (b < 76) return 'Adagio';
    if (b < 92) return 'Andante';
    if (b < 108) return 'Moderato';
    if (b < 120) return 'Allegro moderato';
    if (b < 156) return 'Allegro';
    if (b < 176) return 'Vivace';
    if (b < 200) return 'Presto';
    return 'Prestissimo';
  }
}
