import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  bool _initialized = false;
  bool _musicOn = true;
  bool _sfxOn = true;
  final double _musicVolume = 0.6;
  final double _sfxVolume = 0.9;
  AudioPlayer? _musicPlayer;

  bool get isInitialized => _initialized;
  bool get musicOn => _musicOn;
  bool get sfxOn => _sfxOn;

  Future<void> init() async {
    if (_initialized) return;
    unawaited(Future(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        _musicOn = prefs.getBool('audio_music') ?? _musicOn;
        _sfxOn = prefs.getBool('audio_sfx') ?? _sfxOn;
      } catch (_) {}
    }));
    try {
      await FlameAudio.audioCache.loadAll([
        'jump.wav',
        'punch.wav',
        'hit.wav',
        'fall.wav',
        'powerup.wav',
        'win.wav',
        'bgm.mp3',
      ]).timeout(const Duration(seconds: 2));
    } catch (_) {}
    _initialized = true;
  }

  Future<void> playBgm() async {
    if (!_musicOn || !_initialized) return;
    try {
      // tenta tocar loop
      _musicPlayer?.stop();
      _musicPlayer = await FlameAudio.loop('bgm.mp3', volume: _musicVolume).timeout(const Duration(seconds: 1));
    } catch (_) {
      // sem arquivo, apenas ignora - não quebra jogo
    }
  }

  Future<void> stopBgm() async {
    try {
      await _musicPlayer?.stop();
    } catch (_) {}
  }

  Future<void> playSfx(String file) async {
    if (!_sfxOn || !_initialized) return;
    try {
      await FlameAudio.play(file, volume: _sfxVolume).timeout(const Duration(seconds: 1));
    } catch (_) {}
  }

  void playJump() => playSfx('jump.wav');
  void playPunch() => playSfx('punch.wav');
  void playHit() => playSfx('hit.wav');
  void playFall() => playSfx('fall.wav');
  void playPowerUp() => playSfx('powerup.wav');
  void playWin() => playSfx('win.wav');

  void setMusic(bool on) {
    _musicOn = on;
    unawaited(Future(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('audio_music', on);
      } catch (_) {}
    }));
    if (!on) {
      stopBgm();
    } else {
      playBgm();
    }
  }

  void setSfx(bool on) {
    _sfxOn = on;
    unawaited(Future(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('audio_sfx', on);
      } catch (_) {}
    }));
  }

  void dispose() {
    try {
      _musicPlayer?.dispose();
    } catch (_) {}
    // FlameAudio.bgm is global - avoid disposing in tests to prevent MissingPluginException
  }
}

// Singleton global simples
final audioManager = AudioManager();
