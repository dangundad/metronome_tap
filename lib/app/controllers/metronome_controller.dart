import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

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

  // Tap tempo
  final _tapTimes = <DateTime>[];
  final tapCount = 0.obs; // visible tap counter
  Timer? _tapResetTimer;

  // Absolute-time beat scheduler (drift-free)
  Timer? _beatTimer;
  DateTime? _nextBeatTime; // wall-clock time of next scheduled beat

  @override
  void onInit() {
    super.onInit();
    _loadPrefs();
  }

  @override
  void onClose() {
    _beatTimer?.cancel();
    _tapResetTimer?.cancel();
    super.onClose();
  }

  void _loadPrefs() {
    bpm.value = HiveService.to.getAppData<int>(_bpmKey) ?? 120;
    timeSignature.value = HiveService.to.getAppData<int>(_tsKey) ?? 4;
    hapticEnabled.value =
        HiveService.to.getAppData<bool>(_hapticKey) ?? true;
    isSoundEnabled.value =
        HiveService.to.getAppData<bool>(_soundKey) ?? true;
  }

  void _savePrefs() {
    HiveService.to.setAppData(_bpmKey, bpm.value);
    HiveService.to.setAppData(_tsKey, timeSignature.value);
    HiveService.to.setAppData(_hapticKey, hapticEnabled.value);
    HiveService.to.setAppData(_soundKey, isSoundEnabled.value);
  }

  // ─── Controls ─────────────────────────────────────────
  void toggle() => isPlaying.value ? stop() : start();

  void start() {
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
      // Compute the new next-beat time from now (preserving beat phase
      // as best as possible at the new tempo).
      _rescheduleFromNow();
    }
    _savePrefs();
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
    // this callback actually ran — this prevents cumulative drift.
    _nextBeatTime = _nextBeatTime!.add(_intervalDuration);
    _scheduleNextTimer();
  }

  Duration get _intervalDuration =>
      Duration(microseconds: (60000000 / bpm.value).round());

  void _fireBeat() {
    final ts = timeSignature.value;
    final next = (activeBeat.value + 1) % ts;
    activeBeat.value = next;

    if (isSoundEnabled.value) {
      SystemSound.play(SystemSoundType.click);
    }

    if (hapticEnabled.value) {
      if (next == 0) {
        HapticFeedback.heavyImpact(); // Accent (downbeat)
      } else {
        HapticFeedback.mediumImpact();
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
      int totalMs = 0;
      for (int i = 1; i < _tapTimes.length; i++) {
        totalMs +=
            _tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds;
      }
      final avgInterval = totalMs / (_tapTimes.length - 1);
      final newBpm =
          (60000 / avgInterval).round().clamp(_minBpm, _maxBpm);
      setBpm(newBpm);
    }
  }

  // ─── BPM helpers ──────────────────────────────────────
  int get minBpm => _minBpm;
  int get maxBpm => _maxBpm;

  String get tempoLabel {
    final b = bpm.value;
    if (b < 60) return 'Largo';
    if (b < 66) return 'Larghetto';
    if (b < 76) return 'Adagio';
    if (b < 108) return 'Andante';
    if (b < 120) return 'Moderato';
    if (b < 156) return 'Allegro';
    if (b < 176) return 'Vivace';
    if (b < 200) return 'Presto';
    return 'Prestissimo';
  }
}
