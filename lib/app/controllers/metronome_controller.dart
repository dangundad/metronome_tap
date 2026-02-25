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

  Timer? _beatTimer;

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
    _scheduleBeat();
  }

  void stop() {
    _beatTimer?.cancel();
    isPlaying.value = false;
    activeBeat.value = -1;
  }

  void setBpm(int value) {
    bpm.value = value.clamp(_minBpm, _maxBpm);
    if (isPlaying.value) {
      _beatTimer?.cancel();
      _scheduleBeat();
    }
    _savePrefs();
  }

  void setTimeSignature(int beats) {
    timeSignature.value = beats;
    activeBeat.value = -1;
    if (isPlaying.value) {
      _beatTimer?.cancel();
      _scheduleBeat();
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

  // ─── Beat scheduling ──────────────────────────────────
  void _scheduleBeat() {
    _fireBeat(); // First beat immediately
    final intervalMs = (60000 / bpm.value).round();
    _beatTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => _fireBeat(),
    );
  }

  void _fireBeat() {
    final ts = timeSignature.value;
    final next = (activeBeat.value + 1) % ts;
    activeBeat.value = next;

    if (isSoundEnabled.value) {
      // SystemSound.click for every beat (downbeat and weak beats alike)
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
    tapCount.value = _tapTimes.length;

    // Keep only last 8 taps
    if (_tapTimes.length > 8) _tapTimes.removeAt(0);

    if (_tapTimes.length >= 2) {
      int totalMs = 0;
      for (int i = 1; i < _tapTimes.length; i++) {
        totalMs +=
            _tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds;
      }
      final avgInterval = totalMs / (_tapTimes.length - 1);
      final newBpm = (60000 / avgInterval).round().clamp(_minBpm, _maxBpm);
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
