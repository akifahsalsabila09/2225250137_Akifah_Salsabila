import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum Sfx {
  koin('audio/koin.wav'),
  lompat('audio/lompat.wav'),
  tabrak('audio/tabrak.wav'),
  benar('audio/benar.wav'),
  salah('audio/salah.wav'),
  finish('audio/finish.wav');

  const Sfx(this.asset);
  final String asset;
}

/// Musik latar dan efek suara permainan.
/// Semua pemanggilan aman: bila suara gagal diputar (misalnya diblokir browser), permainan tetap jalan.
class GameAudio {
  GameAudio._();
  static final GameAudio instance = GameAudio._();

  /// Dimatikan di test (tidak ada plugin audio di lingkungan test).
  static bool disabled = false;

  bool _muted = false;
  bool _musicWanted = false;
  AudioPlayer? _music;
  final List<AudioPlayer> _sfx = [];
  int _next = 0;

  bool get muted => _muted;

  Future<void> _safe(Future<void> Function() f) async {
    if (disabled) return;
    try {
      await f();
    } catch (e) {
      debugPrint('Audio: $e');
    }
  }

  Future<void> setMuted(bool m) async {
    _muted = m;
    if (m) {
      await _safe(() async => _music?.pause());
    } else if (_musicWanted) {
      await _startOrResume();
    }
  }

  Future<void> _startOrResume() => _safe(() async {
        if (_music == null) {
          _music = AudioPlayer(playerId: 'musik');
          await _music!.setReleaseMode(ReleaseMode.loop);
          await _music!.setVolume(0.35);
          await _music!.play(AssetSource('audio/musik.wav'));
        } else {
          await _music!.resume();
        }
      });

  /// Mulai/lanjutkan musik latar (dipanggil saat menggowes).
  Future<void> playMusic() async {
    _musicWanted = true;
    if (_muted) return;
    await _startOrResume();
  }

  /// Jeda musik (saat soal atau chat AI terbuka, agar siswa fokus).
  Future<void> pauseMusic() async {
    _musicWanted = false;
    await _safe(() async => _music?.pause());
  }

  Future<void> stopMusic() async {
    _musicWanted = false;
    await _safe(() async {
      await _music?.stop();
    });
  }

  Future<void> play(Sfx s) async {
    if (_muted) return;
    await _safe(() async {
      if (_sfx.length < 4) {
        final p = AudioPlayer(playerId: 'sfx${_sfx.length}');
        await p.setReleaseMode(ReleaseMode.stop);
        _sfx.add(p);
      }
      final p = _sfx[_next % _sfx.length];
      _next++;
      await p.stop();
      await p.play(AssetSource(s.asset), volume: s == Sfx.tabrak ? 0.6 : 0.8);
    });
  }
}
