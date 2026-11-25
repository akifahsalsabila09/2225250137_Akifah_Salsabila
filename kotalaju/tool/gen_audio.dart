// Membuat musik latar & efek suara KotaLaju (komposisi orisinal, gaya chiptune).
// Jalankan dari folder kotalaju:  dart run tool/gen_audio.dart
// Hasil: assets/audio/*.wav (mono, 22.050 Hz, 16-bit).
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sr = 22050;

double midi(int n) => 440.0 * pow(2, (n - 69) / 12);

double square(double phase, [double duty = 0.5]) => (phase % 1.0) < duty ? 1.0 : -1.0;
double triangle(double phase) {
  final p = phase % 1.0;
  return p < 0.5 ? 4 * p - 1 : 3 - 4 * p;
}

/// Menambahkan satu nada ke buffer.
void addTone(List<double> buf, double startSec, double durSec, double freq, double vol,
    {String wave = 'square', double duty = 0.5, double attack = 0.005, double release = 0.04, double slideTo = 0}) {
  final start = (startSec * sr).round();
  final len = (durSec * sr).round();
  var phase = 0.0;
  for (var i = 0; i < len && start + i < buf.length; i++) {
    final t = i / sr;
    final f = slideTo > 0 ? freq + (slideTo - freq) * (i / len) : freq;
    phase += f / sr;
    final s = switch (wave) {
      'tri' => triangle(phase),
      'sine' => sin(2 * pi * phase),
      _ => square(phase, duty),
    };
    var env = 1.0;
    if (t < attack) env = t / attack;
    final remain = durSec - t;
    if (remain < release) env *= max(0, remain / release);
    // peluruhan ringan agar tidak berdengung
    env *= exp(-t * 1.8);
    buf[start + i] += s * vol * env;
  }
}

void addNoise(List<double> buf, double startSec, double durSec, double vol, Random rnd, {double decay = 30}) {
  final start = (startSec * sr).round();
  final len = (durSec * sr).round();
  var last = 0.0;
  for (var i = 0; i < len && start + i < buf.length; i++) {
    final t = i / sr;
    final n = rnd.nextDouble() * 2 - 1;
    last = last * 0.6 + n * 0.4; // sedikit diredam
    buf[start + i] += last * vol * exp(-t * decay);
  }
}

void writeWav(String path, List<double> samples, {double peak = 0.85}) {
  var maxAbs = 0.0;
  for (final s in samples) {
    maxAbs = max(maxAbs, s.abs());
  }
  final gain = maxAbs == 0 ? 1.0 : peak / maxAbs;
  final data = ByteData(44 + samples.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sr, Endian.little);
  data.setUint32(28, sr * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i] * gain).clamp(-1.0, 1.0);
    data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data.buffer.asUint8List());
  stdout.writeln('${path.padRight(32)} ${(samples.length / sr).toStringAsFixed(2)} s  ${(data.lengthInBytes / 1024).round()} KB');
}

List<double> blank(double sec) => List<double>.filled((sec * sr).round(), 0);

void main() {
  final rnd = Random(7);
  const dir = 'assets/audio';

  // ── Musik latar: 8 birama, 132 bpm, progresi C–G–Am–F–C–G–F–G (komposisi orisinal) ──
  const bpm = 132.0;
  const eighth = 60 / bpm / 2;
  const melody = [
    [72, 76, 79, 76, 77, 76, 74, 72],
    [74, 71, 67, 71, 74, -1, 79, 77],
    [76, 72, 69, 72, 76, 77, 79, -1],
    [77, 76, 74, 72, 74, -1, 72, -1],
    [72, 76, 79, 84, 83, 79, 76, 79],
    [79, 74, 71, 74, 79, 81, 79, 77],
    [77, 81, 84, 81, 79, 77, 76, 74],
    [74, 76, 77, 79, 74, -1, 71, -1],
  ];
  const bassRoots = [48, 43, 45, 41, 48, 43, 41, 43]; // C2 G1 A1 F1 ...
  const chordTones = [
    [60, 64, 67],
    [59, 62, 67],
    [60, 64, 69],
    [60, 65, 69],
    [60, 64, 67],
    [59, 62, 67],
    [60, 65, 69],
    [59, 62, 67],
  ];
  final music = blank(8 * 8 * eighth);
  for (var bar = 0; bar < 8; bar++) {
    for (var k = 0; k < 8; k++) {
      final t = (bar * 8 + k) * eighth;
      final n = melody[bar][k];
      if (n > 0) addTone(music, t, eighth * 0.92, midi(n), 0.22, duty: 0.25);
      // bas (seperempat ketukan, oktaf naik-turun)
      if (k.isEven) {
        final root = bassRoots[bar] + (k % 4 == 2 ? 12 : 0);
        addTone(music, t, eighth * 1.8, midi(root), 0.35, wave: 'tri', release: 0.08);
      }
      // akor arpeggio halus
      final c = chordTones[bar][k % 3];
      addTone(music, t, eighth * 0.8, midi(c), 0.07, duty: 0.5);
      // drum: kick di ketukan 1 & 3, hi-hat di setiap ketukan lepas
      if (k == 0 || k == 4) addTone(music, t, 0.12, 110, 0.45, wave: 'sine', slideTo: 45, release: 0.05);
      if (k == 2 || k == 6) addNoise(music, t, 0.12, 0.18, rnd, decay: 25);
      if (k.isOdd) addNoise(music, t, 0.04, 0.07, rnd, decay: 90);
    }
  }
  writeWav('$dir/musik.wav', music, peak: 0.7);

  // ── Efek suara ──
  final coin = blank(0.32);
  addTone(coin, 0, 0.07, 988, 0.5, duty: 0.5);
  addTone(coin, 0.07, 0.24, 1319, 0.5, duty: 0.5, release: 0.15);
  writeWav('$dir/koin.wav', coin);

  final jump = blank(0.22);
  addTone(jump, 0, 0.2, 380, 0.6, wave: 'square', duty: 0.25, slideTo: 900, release: 0.06);
  writeWav('$dir/lompat.wav', jump, peak: 0.6);

  final hit = blank(0.35);
  addNoise(hit, 0, 0.3, 0.8, rnd, decay: 14);
  addTone(hit, 0, 0.25, 140, 0.7, wave: 'sine', slideTo: 60, release: 0.1);
  writeWav('$dir/tabrak.wav', hit, peak: 0.7);

  final correct = blank(0.55);
  for (final (i, n) in [72, 76, 79, 84].indexed) {
    addTone(correct, i * 0.08, i == 3 ? 0.3 : 0.09, midi(n), 0.5, wave: 'tri', release: 0.05);
    addTone(correct, i * 0.08, i == 3 ? 0.3 : 0.09, midi(n + 12), 0.12, duty: 0.25);
  }
  writeWav('$dir/benar.wav', correct);

  final wrong = blank(0.45);
  addTone(wrong, 0, 0.18, 330, 0.45, duty: 0.5);
  addTone(wrong, 0.2, 0.25, 247, 0.45, duty: 0.5, release: 0.1);
  writeWav('$dir/salah.wav', wrong, peak: 0.6);

  final finish = blank(1.3);
  for (final (i, (n, d)) in [(72, 0.12), (76, 0.12), (79, 0.12), (84, 0.7)].indexed) {
    final t = i * 0.13;
    addTone(finish, t, d, midi(n), 0.4, duty: 0.25, release: 0.1);
    addTone(finish, t, d, midi(n - 12), 0.3, wave: 'tri', release: 0.1);
  }
  addTone(finish, 0.39, 0.7, midi(76), 0.2, duty: 0.5, release: 0.2);
  addTone(finish, 0.39, 0.7, midi(79), 0.2, duty: 0.5, release: 0.2);
  writeWav('$dir/finish.wav', finish);
}
