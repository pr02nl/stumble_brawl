import 'package:flutter_test/flutter_test.dart';
import 'package:stumble_brawl/src/audio/audio_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AudioManager', () {
    test('initial state not initialized', () {
      final m = AudioManager();
      expect(m.isInitialized, false);
      expect(m.musicOn, true);
      expect(m.sfxOn, true);
    });

    test('init sets initialized', () async {
      final m = AudioManager();
      await m.init();
      expect(m.isInitialized, true);
      // second init is no-op
      await m.init();
      expect(m.isInitialized, true);
    });

    test('setMusic/sfx toggles', () async {
      final m = AudioManager();
      await m.init();
      m.setMusic(false);
      expect(m.musicOn, false);
      // avoid calling true which triggers playBgm that may hang in test
      m.setSfx(false);
      expect(m.sfxOn, false);
      m.setSfx(true);
      expect(m.sfxOn, true);
      // test true separately with timeout
      m.setMusic(true);
      expect(m.musicOn, true);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('play methods do not throw without assets', () async {
      final m = AudioManager();
      // not initialized - should be no-op and not throw
      expect(() => m.playJump(), returnsNormally);
      expect(() => m.playPunch(), returnsNormally);
      expect(() => m.playHit(), returnsNormally);
      expect(() => m.playFall(), returnsNormally);
      expect(() => m.playPowerUp(), returnsNormally);
      expect(() => m.playWin(), returnsNormally);
      m.dispose();
    });

    test('singleton audioManager', () {
      expect(audioManager, isA<AudioManager>());
    });

    test('play without init is no-op', () async {
      final m = AudioManager();
      // not initialized
      await m.playBgm();
      await m.playSfx('jump.wav');
      expect(m.isInitialized, false);
    });
  });
}
