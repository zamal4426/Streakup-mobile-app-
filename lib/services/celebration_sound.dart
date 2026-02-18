import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class CelebrationSound {
  static final AudioPlayer _player = AudioPlayer();
  static String? _cachedPath;
  static String? _cachedTimerPath;

  /// Play a party-popper style celebration sound.
  static Future<void> play() async {
    try {
      final path = await _getOrCreateSound();
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      debugPrint('CelebrationSound error: $e');
    }
  }

  /// Play a distinct timer-end bell sound (gentle ding-ding-ding).
  static Future<void> playTimerEnd() async {
    try {
      final path = await _getOrCreateTimerSound();
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      debugPrint('TimerSound error: $e');
    }
  }

  static Future<String> _getOrCreateSound() async {
    if (_cachedPath != null && File(_cachedPath!).existsSync()) {
      return _cachedPath!;
    }

    final dir = Directory.systemTemp;
    final file = File('${dir.path}/celebration_popper_v2.wav');

    if (!file.existsSync()) {
      final bytes = _generatePopperWav();
      await file.writeAsBytes(bytes);
    }

    _cachedPath = file.path;
    return _cachedPath!;
  }

  static Future<String> _getOrCreateTimerSound() async {
    if (_cachedTimerPath != null && File(_cachedTimerPath!).existsSync()) {
      return _cachedTimerPath!;
    }

    final dir = Directory.systemTemp;
    final file = File('${dir.path}/timer_bell_v1.wav');

    if (!file.existsSync()) {
      final bytes = _generateTimerBellWav();
      await file.writeAsBytes(bytes);
    }

    _cachedTimerPath = file.path;
    return _cachedTimerPath!;
  }

  /// Generate a party-popper / confetti-cannon celebration sound.
  /// Layers: pop burst → sparkle shimmer → triumphant fanfare.
  /// ~1.3 seconds, 44100 Hz, 16-bit mono PCM.
  static Uint8List _generatePopperWav() {
    const sampleRate = 44100;
    const totalDuration = 2.0;
    final totalSamples = (sampleRate * totalDuration).toInt();
    final rng = Random(42);

    final pcmData = Float64List(totalSamples);

    // ── Layer 1: Pop burst (0–80ms) ──
    // Short noise burst that sounds like a popper firing
    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      if (t < 0.08) {
        final envelope = (1.0 - t / 0.08);
        // Filtered noise — band-pass feel
        final noise = (rng.nextDouble() * 2 - 1);
        pcmData[i] += noise * envelope * envelope * 0.7;
      }
    }

    // ── Layer 2: Sparkle shimmer (30ms–900ms) ──
    // Random high-pitched tinkle particles, like confetti falling
    final sparkleCount = 25;
    for (var s = 0; s < sparkleCount; s++) {
      final sparkleStart = 0.03 + rng.nextDouble() * 0.5;
      final sparkleDur = 0.06 + rng.nextDouble() * 0.12;
      final sparkleFreq =
          2000.0 + rng.nextDouble() * 4000.0; // 2–6 kHz sparkle
      final sparkleVol = 0.05 + rng.nextDouble() * 0.1;
      final panPhase = rng.nextDouble() * 2 * pi;

      for (var i = 0; i < totalSamples; i++) {
        final t = i / sampleRate;
        final st = t - sparkleStart;
        if (st >= 0 && st < sparkleDur) {
          final env = (1.0 - st / sparkleDur);
          final wave = sin(2 * pi * sparkleFreq * st + panPhase);
          pcmData[i] += wave * env * env * sparkleVol;
        }
      }
    }

    // ── Layer 3: Triumphant fanfare melody (50ms–1200ms) ──
    // Ascending notes with rich harmonics, like a victory jingle
    const fanfareNotes = [
      // [freq, startTime, duration, volume]
      [523.25, 0.05, 0.18, 0.35], // C5
      [659.25, 0.16, 0.18, 0.38], // E5
      [783.99, 0.28, 0.18, 0.40], // G5
      [1046.50, 0.40, 0.70, 0.45], // C6 (held longer — the triumphant note)
    ];

    for (final note in fanfareNotes) {
      final freq = note[0];
      final noteStart = note[1];
      final noteDur = note[2];
      final vol = note[3];

      for (var i = 0; i < totalSamples; i++) {
        final t = i / sampleRate;
        final nt = t - noteStart;
        if (nt >= 0 && nt < noteDur + 0.2) {
          // Attack-decay-sustain-release envelope
          double env;
          if (nt < 0.008) {
            env = nt / 0.008; // 8ms attack
          } else if (nt < 0.04) {
            env = 1.0 - (nt - 0.008) / 0.04 * 0.2; // slight decay
          } else if (nt < noteDur) {
            env = 0.8; // sustain
          } else {
            env = 0.8 * (1.0 - (nt - noteDur) / 0.2); // release
          }
          env = env.clamp(0.0, 1.0);

          // Rich bell-like tone: fundamental + harmonics
          var wave = sin(2 * pi * freq * nt) * 0.55 +
              sin(2 * pi * freq * 2 * nt) * 0.22 +
              sin(2 * pi * freq * 3 * nt) * 0.12 +
              sin(2 * pi * freq * 4 * nt) * 0.06 +
              sin(2 * pi * freq * 5 * nt) * 0.03;

          pcmData[i] += wave * env * vol;
        }
      }
    }

    // ── Layer 4: Sub-bass thump (0–60ms) ──
    // Adds a satisfying low-end "thud" to the pop
    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      if (t < 0.06) {
        final env = (1.0 - t / 0.06);
        final wave = sin(2 * pi * 80 * t); // 80 Hz thump
        pcmData[i] += wave * env * env * env * 0.4;
      }
    }

    // ── Layer 5: Shimmer tail (600ms–2000ms) ──
    // Gentle fading sparkle that trails off
    for (var s = 0; s < 20; s++) {
      final start = 0.6 + rng.nextDouble() * 0.8;
      final dur = 0.15 + rng.nextDouble() * 0.3;
      final freq = 1500.0 + rng.nextDouble() * 3000.0;
      final vol = 0.02 + rng.nextDouble() * 0.05;

      for (var i = 0; i < totalSamples; i++) {
        final t = i / sampleRate;
        final st = t - start;
        if (st >= 0 && st < dur) {
          final env = (1.0 - st / dur);
          pcmData[i] += sin(2 * pi * freq * st) * env * env * vol;
        }
      }
    }

    // ── Normalize & convert to 16-bit PCM ──
    double maxVal = 0;
    for (var i = 0; i < totalSamples; i++) {
      final abs = pcmData[i].abs();
      if (abs > maxVal) maxVal = abs;
    }
    final scale = maxVal > 0 ? 28000.0 / maxVal : 1.0;

    final pcm16 = Int16List(totalSamples);
    for (var i = 0; i < totalSamples; i++) {
      pcm16[i] = (pcmData[i] * scale).clamp(-32768, 32767).toInt();
    }

    // ── Build WAV file ──
    final dataSize = totalSamples * 2;
    final fileSize = 36 + dataSize;
    final buffer = ByteData(44 + dataSize);
    var offset = 0;

    // RIFF header
    for (final c in [0x52, 0x49, 0x46, 0x46]) {
      buffer.setUint8(offset++, c);
    }
    buffer.setUint32(offset, fileSize, Endian.little);
    offset += 4;
    for (final c in [0x57, 0x41, 0x56, 0x45]) {
      buffer.setUint8(offset++, c);
    }

    // fmt chunk
    for (final c in [0x66, 0x6D, 0x74, 0x20]) {
      buffer.setUint8(offset++, c);
    }
    buffer.setUint32(offset, 16, Endian.little);
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // PCM
    offset += 2;
    buffer.setUint16(offset, 1, Endian.little); // mono
    offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, sampleRate * 2, Endian.little);
    offset += 4;
    buffer.setUint16(offset, 2, Endian.little);
    offset += 2;
    buffer.setUint16(offset, 16, Endian.little);
    offset += 2;

    // data chunk
    for (final c in [0x64, 0x61, 0x74, 0x61]) {
      buffer.setUint8(offset++, c);
    }
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    for (var i = 0; i < totalSamples; i++) {
      buffer.setInt16(offset, pcm16[i], Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  /// Generate a gentle bell/chime sound for timer completion.
  /// 3 ascending dings with reverb tail — distinct "time's up" vibe.
  static Uint8List _generateTimerBellWav() {
    const sampleRate = 44100;
    const totalDuration = 2.5;
    final totalSamples = (sampleRate * totalDuration).toInt();

    final pcmData = Float64List(totalSamples);

    // Three ascending bell strikes
    const bells = [
      [880.0, 0.0, 0.6],    // A5 — first ding
      [1108.73, 0.4, 0.6],  // C#6 — second ding
      [1318.51, 0.8, 1.2],  // E6 — final ding (longer ring)
    ];

    for (final bell in bells) {
      final freq = bell[0];
      final start = bell[1];
      final dur = bell[2];

      for (var i = 0; i < totalSamples; i++) {
        final t = i / sampleRate;
        final bt = t - start;
        if (bt < 0 || bt > dur) continue;

        // Sharp attack, smooth exponential decay (bell-like)
        double env;
        if (bt < 0.003) {
          env = bt / 0.003; // 3ms attack
        } else {
          env = exp(-4.0 * bt / dur); // exponential decay
        }

        // Bell tone: fundamental + inharmonic partials (metallic character)
        var wave = sin(2 * pi * freq * bt) * 0.45 +
            sin(2 * pi * freq * 2.0 * bt) * 0.20 +
            sin(2 * pi * freq * 2.92 * bt) * 0.12 + // inharmonic — bell-like
            sin(2 * pi * freq * 4.16 * bt) * 0.08 +
            sin(2 * pi * freq * 5.43 * bt) * 0.04;

        pcmData[i] += wave * env * 0.5;
      }
    }

    // Normalize & convert to 16-bit PCM
    double maxVal = 0;
    for (var i = 0; i < totalSamples; i++) {
      final abs = pcmData[i].abs();
      if (abs > maxVal) maxVal = abs;
    }
    final scale = maxVal > 0 ? 28000.0 / maxVal : 1.0;

    final pcm16 = Int16List(totalSamples);
    for (var i = 0; i < totalSamples; i++) {
      pcm16[i] = (pcmData[i] * scale).clamp(-32768, 32767).toInt();
    }

    // Build WAV file
    final dataSize = totalSamples * 2;
    final fileSize = 36 + dataSize;
    final buffer = ByteData(44 + dataSize);
    var offset = 0;

    for (final c in [0x52, 0x49, 0x46, 0x46]) {
      buffer.setUint8(offset++, c);
    }
    buffer.setUint32(offset, fileSize, Endian.little);
    offset += 4;
    for (final c in [0x57, 0x41, 0x56, 0x45]) {
      buffer.setUint8(offset++, c);
    }
    for (final c in [0x66, 0x6D, 0x74, 0x20]) {
      buffer.setUint8(offset++, c);
    }
    buffer.setUint32(offset, 16, Endian.little);
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little);
    offset += 2;
    buffer.setUint16(offset, 1, Endian.little);
    offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, sampleRate * 2, Endian.little);
    offset += 4;
    buffer.setUint16(offset, 2, Endian.little);
    offset += 2;
    buffer.setUint16(offset, 16, Endian.little);
    offset += 2;
    for (final c in [0x64, 0x61, 0x74, 0x61]) {
      buffer.setUint8(offset++, c);
    }
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    for (var i = 0; i < totalSamples; i++) {
      buffer.setInt16(offset, pcm16[i], Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}
