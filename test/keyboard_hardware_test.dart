import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:stumble_brawl/src/audio/audio_manager.dart';
import 'package:stumble_brawl/src/game/stumble_brawl_game.dart';

void main() {
  setUp(() {
    audioManager.setSfx(false);
    audioManager.setMusic(false);
  });
  group('HardwareKeyboardDetector - Web facilitado', () {
    testWidgets('WASD e Setas movem P1 no single player', (tester) async {
      final game = StumbleBrawlGame(humanSkins: [0], botSkins: [1, 2, 3]);
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (game.players.length == 4) break;
      }
      expect(game.players.length, 4);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.humanInputs[0].x, -1);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.humanInputs[0].x, 1);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.humanInputs[0].x, -1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Espaço/W pulo e F/J soco', (tester) async {
      final game = StumbleBrawlGame(humanSkins: [0], botSkins: [1, 2, 3]);
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (game.players.isNotEmpty) break;
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      expect(game.humanInputs[0].jump, true);
      expect(game.humanInputs[0].jumpPressedThisFrame, true);
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.humanInputs[0].jump, true);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.humanInputs[0].jump, false);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
      expect(game.humanInputs[0].punch, true);
      expect(game.humanInputs[0].punchPressedThisFrame, true);
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.humanInputs[0].punch, true);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.humanInputs[0].punch, false);
      await tester.pump(const Duration(milliseconds: 1000));
    });

    testWidgets('Multi 2 jogadores - WASD vs Setas', (tester) async {
      final game = StumbleBrawlGame(humanSkins: [0, 1], botSkins: [2, 3]);
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (game.players.length == 4) break;
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.humanInputs[0].x, -1);
      expect(game.humanInputs[1].x, 0);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.humanInputs[1].x, 1);
      expect(game.humanInputs[0].x, 0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('nenhuma tecla não move', (tester) async {
      final game = StumbleBrawlGame(humanSkins: [0], botSkins: [1]);
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (game.players.length == 2) break;
      }
      // garante que sem tecla, x=0
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.humanInputs[0].x, 0);
      expect(game.humanInputs[0].jump, false);
      expect(game.humanInputs[0].punch, false);
      await tester.pump(const Duration(milliseconds: 1000));
    });
  });
}
