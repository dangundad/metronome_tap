import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

import 'package:metronome_tap/app/controllers/setting_controller.dart';
import 'package:metronome_tap/app/services/hive_service.dart';

enum BeatAccent { strong, normal, mute }

class MetronomeController extends GetxController {
  static MetronomeController get to => Get.find();

  static const int _minBpm = 40;
  static const int _maxBpm = 280;

  /// Predefined time signature options: (numerator, denominator)
  static const List<(int, int)> tsOptions = [
    (2, 4),
    (3, 4),
    (4, 4),
    (5, 4),
    (6, 8),
    (7, 8),
  ];

  // Hive keys
  static const _bpmKey = 'metro_bpm';
  static const _tsKey = 'metro_time_sig';
  static const _tsDenomKey = 'metro_ts_denom';
  static const _hapticKey = 'metro_haptic';
  static const _soundKey = 'metro_sound';
  static const _subdivKey = 'metro_subdivision';
  static const _accentsKey = 'metro_accents';

  // State
  final bpm = 120.obs;
  final timeSignature = 4.obs; // beats per measure (numerator)
  final timeSigDenom = 4.obs; // denominator (4 or 8)
  final subdivision = 1.obs; // 1=quarter, 2=eighth, 3=triplet, 4=sixteenth
  final isPlaying = false.obs;
  final activeBeat = (-1).obs; // -1 = stopped
  final activeSubBeat = 0.obs; // 0 to subdivision-1
  final hapticEnabled = true.obs;
  final isSoundEnabled = true.obs;
  final accents = <BeatAccent>[].obs;

  bool _hasVibrator = false;
  int _tickCount = -1;

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
  DateTime? _nextBeatTime; // wall-clock time of next scheduled tick

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
    unawaited(HiveService.to.setAppData(_bpmKey, bpm.value));
    _saveBpmDebounce?.cancel();
    super.onClose();
  }

  /// Initialize vibrator check once and await it properly.
  Future<void> _initVibrator() async {
    final result = await Vibration.hasVibrator();
    _hasVibrator = result;
  }

  /// Cache the SettingController reference so _fireTick doesn't need
  /// Get.isRegistered on every tick.
  void _cacheSettingController() {
    if (Get.isRegistered<SettingController>()) {
      _settingCtrl = SettingController.to;
    }
  }

  void _loadPrefs() {
    bpm.value = HiveService.to.getAppData<int>(_bpmKey) ?? 120;
    timeSignature.value = HiveService.to.getAppData<int>(_tsKey) ?? 4;
    timeSigDenom.value = HiveService.to.getAppData<int>(_tsDenomKey) ?? 4;
    hapticEnabled.value = HiveService.to.getAppData<bool>(_hapticKey) ?? true;
    isSoundEnabled.value = HiveService.to.getAppData<bool>(_soundKey) ?? true;
    subdivision.value = (HiveService.to.getAppData<int>(_subdivKey) ?? 1).clamp(
      1,
      4,
    );

    // Load accents or reset to defaults
    final savedAccents = HiveService.to.getAppData<List>(_accentsKey);
    if (savedAccents != null && savedAccents.length == timeSignature.value) {
      accents.value = savedAccents
          .map((v) => BeatAccent.values[(v as int).clamp(0, 2)])
          .toList();
    } else {
      _resetAccents();
    }

    // Sync from SettingController if available
    if (_settingCtrl != null) {
      hapticEnabled.value = _settingCtrl!.hapticEnabled.value;
      isSoundEnabled.value = _settingCtrl!.soundEnabled.value;
    }
  }

  void _savePrefs() {
    HiveService.to.setAppData(_bpmKey, bpm.value);
    HiveService.to.setAppData(_tsKey, timeSignature.value);
    HiveService.to.setAppData(_tsDenomKey, timeSigDenom.value);
    HiveService.to.setAppData(_hapticKey, hapticEnabled.value);
    HiveService.to.setAppData(_soundKey, isSoundEnabled.value);
    HiveService.to.setAppData(_subdivKey, subdivision.value);
    HiveService.to.setAppData(
      _accentsKey,
      accents.map((a) => a.index).toList(),
    );
  }

  /// Save BPM with debounce to avoid excessive Hive writes during slider drag.
  void _saveBpmDebounced() {
    _saveBpmDebounce?.cancel();
    _saveBpmDebounce = Timer(const Duration(milliseconds: 500), () {
      HiveService.to.setAppData(_bpmKey, bpm.value);
    });
  }

  void _resetAccents() {
    accents.value = List.generate(
      timeSignature.value,
      (i) => i == 0 ? BeatAccent.strong : BeatAccent.normal,
    );
  }

  // ─── Controls ─────────────────────────────────────────
  void toggle() => isPlaying.value ? stop() : start();

  void start() {
    // Re-cache in case SettingController was registered after onInit
    _cacheSettingController();
    isPlaying.value = true;
    activeBeat.value = -1;
    activeSubBeat.value = 0;
    _tickCount = -1;
    _startScheduler();
  }

  void stop() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _nextBeatTime = null;
    isPlaying.value = false;
    activeBeat.value = -1;
    activeSubBeat.value = 0;
    _tickCount = -1;
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

  void setTimeSignature(int beats, int denom) {
    timeSignature.value = beats;
    timeSigDenom.value = denom;
    _resetAccents();
    activeBeat.value = -1;
    activeSubBeat.value = 0;
    _tickCount = -1;
    if (isPlaying.value) {
      _startScheduler();
    }
    _savePrefs();
  }

  void setSubdivision(int value) {
    subdivision.value = value.clamp(1, 4);
    activeSubBeat.value = 0;
    _tickCount = -1;
    if (isPlaying.value) {
      _startScheduler();
    }
    _savePrefs();
  }

  void toggleAccent(int beatIndex) {
    if (beatIndex < 0 || beatIndex >= accents.length) return;
    final current = accents[beatIndex];
    accents[beatIndex] = switch (current) {
      BeatAccent.strong => BeatAccent.normal,
      BeatAccent.normal => BeatAccent.mute,
      BeatAccent.mute => BeatAccent.strong,
    };
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
  // Strategy: fire the first tick immediately and track the absolute wall-clock
  // time that each subsequent tick SHOULD occur. Each timer fires slightly early
  // by scheduling for (nextBeatTime - now); if Dart's event loop delivers it a
  // few ms late, the next interval is shortened by that overshoot so the beat
  // grid stays anchored to real time rather than drifting forward.

  void _startScheduler() {
    _beatTimer?.cancel();
    _tickCount = -1;
    _fireTick(); // tick 0 fires immediately
    _nextBeatTime = DateTime.now().add(_tickDuration);
    _scheduleNextTimer();
  }

  /// Reschedule without firing an extra beat (used when BPM changes mid-play).
  void _rescheduleFromNow() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _nextBeatTime = DateTime.now().add(_tickDuration);
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
    _fireTick();

    // Advance the absolute target by exactly one tick regardless of when
    // this callback actually ran -- this prevents cumulative drift.
    _nextBeatTime = _nextBeatTime!.add(_tickDuration);
    _scheduleNextTimer();
  }

  /// Duration of one tick (one subdivision unit).
  Duration get _tickDuration => Duration(
    microseconds: (60000000 / (bpm.value * subdivision.value)).round(),
  );

  void _fireTick() {
    _tickCount++;
    final sub = subdivision.value;
    final ts = timeSignature.value;

    final currentSubBeat = _tickCount % sub;
    final currentBeat = (_tickCount ~/ sub) % ts;

    activeSubBeat.value = currentSubBeat;
    activeBeat.value = currentBeat;

    if (currentSubBeat == 0) {
      // Main beat — apply accent
      final accent = (currentBeat < accents.length)
          ? accents[currentBeat]
          : BeatAccent.normal;
      _playBeatSound(accent);
    } else {
      // Sub-beat — lighter feedback
      _playSubBeatSound();
    }
  }

  void _playBeatSound(BeatAccent accent) {
    if (accent == BeatAccent.mute) return;

    final soundOn = _settingCtrl?.soundEnabled.value ?? isSoundEnabled.value;
    final hapticOn = _settingCtrl?.hapticEnabled.value ?? hapticEnabled.value;

    if (soundOn) {
      SystemSound.play(SystemSoundType.click);
    }

    if (hapticOn && _hasVibrator) {
      switch (accent) {
        case BeatAccent.strong:
          Vibration.vibrate(duration: 200);
        case BeatAccent.normal:
          Vibration.vibrate(duration: 100);
        case BeatAccent.mute:
          break;
      }
    }
  }

  void _playSubBeatSound() {
    final soundOn = _settingCtrl?.soundEnabled.value ?? isSoundEnabled.value;
    final hapticOn = _settingCtrl?.hapticEnabled.value ?? hapticEnabled.value;

    if (soundOn) {
      SystemSound.play(SystemSoundType.click);
    }

    if (hapticOn && _hasVibrator) {
      Vibration.vibrate(duration: 40);
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
        intervals.add(_tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds);
      }

      // Filter outliers: discard intervals that deviate more than 50%
      // from the median to avoid erratic taps skewing the result.
      final filteredIntervals = _filterOutliers(intervals);

      if (filteredIntervals.isNotEmpty) {
        final avgInterval =
            filteredIntervals.reduce((a, b) => a + b) /
            filteredIntervals.length;
        if (avgInterval > 0) {
          final newBpm = (60000 / avgInterval).round().clamp(_minBpm, _maxBpm);
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

    return intervals.where((iv) => (iv - median).abs() <= threshold).toList();
  }

  /// Tap confidence: 0.0 to 1.0 based on interval consistency.
  double get tapConfidence {
    if (_tapTimes.length < 3) return 0.0;

    final intervals = <int>[];
    for (int i = 1; i < _tapTimes.length; i++) {
      intervals.add(_tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds);
    }

    final avg = intervals.reduce((a, b) => a + b) / intervals.length;
    if (avg == 0) return 0.0;

    final variance =
        intervals.map((iv) => (iv - avg) * (iv - avg)).reduce((a, b) => a + b) /
        intervals.length;
    final stdDev = sqrt(variance);
    final cv = stdDev / avg; // coefficient of variation

    if (cv < 0.05) return 1.0;
    if (cv < 0.15) return 0.75;
    if (cv < 0.30) return 0.5;
    return 0.25;
  }

  // ─── Helpers ──────────────────────────────────────────
  int get minBpm => _minBpm;
  int get maxBpm => _maxBpm;

  String get tsLabel => '${timeSignature.value}/${timeSigDenom.value}';

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
