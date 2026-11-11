// Oyunun ses efektlerini üretir: dart run tool/gen_sounds.dart
// Çıktılar assets/audio/ altına yazılır. Aynı adla başka bir WAV dosyası
// koyarak efektleri değiştirebilirsiniz.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const rate = 22050;

/// (frekans Hz, süre sn) notalarından yumuşak zarflı bir melodi üretir.
List<double> melody(List<(double, double)> notes, {double volume = 0.5}) {
  final out = <double>[];
  for (final (freq, dur) in notes) {
    final n = (dur * rate).round();
    for (var i = 0; i < n; i++) {
      final t = i / rate;
      final attack = min(1.0, i / (rate * 0.01));
      final decay = pow(1 - i / n, 1.5).toDouble();
      final wave = sin(2 * pi * freq * t) + 0.3 * sin(4 * pi * freq * t);
      out.add(wave / 1.3 * attack * decay * volume);
    }
  }
  return out;
}

void writeWav(String path, List<double> samples) {
  final data = ByteData(44 + samples.length * 2);
  void str(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(44 + i * 2, v, Endian.little);
  }
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data.buffer.asUint8List());
  stdout.writeln('yazıldı: $path');
}

double midi(int note) => 440.0 * pow(2, (note - 69) / 12);

/// Başa sararken kesinti olmayan, sakin bir arka plan melodisi üretir.
List<double> music() {
  const beat = 0.3; // sekizlik nota süresi (100 vuruş/dk)
  // 8 ölçü; her ölçüde 8 sekizlik. 0 = sus.
  const melody = [
    [72, 0, 76, 79, 76, 0, 72, 0],
    [81, 0, 79, 76, 79, 0, 76, 0],
    [72, 0, 77, 81, 79, 0, 77, 0],
    [79, 0, 74, 79, 74, 0, 74, 0],
    [76, 79, 84, 0, 79, 0, 76, 0],
    [81, 84, 81, 0, 79, 0, 76, 0],
    [77, 0, 81, 79, 77, 0, 74, 0],
    [74, 0, 79, 0, 72, 0, 0, 0],
  ];
  const bass = [48, 45, 41, 43, 48, 45, 41, 43];
  final length = (melody.length * 8 * beat * rate).round();
  final out = List<double>.filled(length, 0);

  // Notanın kuyruğu parçanın sonunu aşarsa başa eklenir; döngü pürüzsüz olur.
  void addNote(
    double start,
    double freq,
    double dur,
    double volume,
    double harmonics,
  ) {
    final n = (dur * rate).round();
    final offset = (start * rate).round();
    for (var i = 0; i < n; i++) {
      final t = i / rate;
      final env = min(1.0, i / (rate * 0.008)) * exp(-t * 5 / dur);
      final wave = sin(2 * pi * freq * t) + harmonics * sin(4 * pi * freq * t);
      out[(offset + i) % length] += wave * env * volume;
    }
  }

  for (var bar = 0; bar < melody.length; bar++) {
    for (var i = 0; i < 8; i++) {
      final note = melody[bar][i];
      if (note != 0) addNote((bar * 8 + i) * beat, midi(note), 0.9, 0.28, 0.25);
    }
    addNote(bar * 8 * beat, midi(bass[bar]), 1.6, 0.3, 0.1);
    addNote((bar * 8 + 4) * beat, midi(bass[bar] + 7), 1.2, 0.18, 0.1);
  }
  final peak = out.map((v) => v.abs()).reduce(max);
  return [for (final v in out) v / peak * 0.7];
}

void main() {
  const dir = 'assets/audio';
  writeWav('$dir/pop.wav', melody([(880, 0.07)], volume: 0.35));
  writeWav(
    '$dir/correct.wav',
    melody([(1046.5, 0.12), (1318.5, 0.12), (1568, 0.25)]),
  );
  writeWav('$dir/wrong.wav', melody([(330, 0.14), (262, 0.22)], volume: 0.3));
  writeWav(
    '$dir/win.wav',
    melody([
      (784, 0.14),
      (1046.5, 0.14),
      (1318.5, 0.14),
      (1568, 0.14),
      (2093, 0.5),
    ]),
  );
  // Ses hafızası oyunundaki dört tuşun notaları.
  for (final (i, note) in [60, 64, 67, 72].indexed) {
    writeWav(
      '$dir/note${i + 1}.wav',
      melody([(midi(note), 0.45)], volume: 0.55),
    );
  }
  // Müzik kutusundaki sekiz çubuk: do majör gamı.
  for (final (i, note) in [60, 62, 64, 65, 67, 69, 71, 72].indexed) {
    writeWav(
      '$dir/xylo${i + 1}.wav',
      melody([(midi(note + 12), 0.5)], volume: 0.55),
    );
  }
  writeWav('$dir/music.wav', music());
}
