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
  group('StumbleBrawlGame integration', () {
    testWidgets('spawns 4 players (1 human + 3 bots)', (tester) async {
      final game = StumbleBrawlGame(humanSkins: [0], botSkins: [1, 2, 3]);
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      // pump until loaded
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (game.players.length == 4) break;
      }
      expect(game.players.length, 4);
      expect(game.players.where((p) => p.isHuman).length, 1);
      expect(game.platforms.length, 11);
    });

    testWidgets('spawns 4 humans when 4 skins', (tester) async {
      final game = StumbleBrawlGame(humanSkins: [0,1,2,3], botSkins: []);
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (game.players.length == 4) break;
      }
      expect(game.players.length, 4);
      expect(game.players.where((p) => p.isHuman).length, 4);
    });

    testWidgets('2 humans + 2 bots', (tester) async {
      final game = StumbleBrawlGame(humanSkins: [0,1], botSkins: [2,3]);
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (game.players.length == 4) break;
      }
      expect(game.players.length, 4);
      expect(game.players.where((p) => p.isHuman).length, 2);
      expect(game.players.where((p) => !p.isHuman).length, 2);
    });

    testWidgets('powerup spawns periodically', (tester) async {
      final game = StumbleBrawlGame(humanSkins: [0], botSkins: [1,2,3]);
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (game.players.isNotEmpty) break;
      }
      // force spawn
      game.nextPowerUpIn = 0.1;
      game.powerUpTimer = 0;
      await tester.pump(const Duration(milliseconds: 200));
      game.update(0.2);
      expect(game.powerUps.length, greaterThanOrEqualTo(1));
      // also check that manual update works
      final count = game.powerUps.length;
      game.nextPowerUpIn = 0.1;
      game.powerUpTimer = 0;
      game.update(0.2);
      expect(game.powerUps.length, greaterThanOrEqualTo(count));
    });

    testWidgets('win condition single alive', (tester) async {
      String? winner;
      bool? isHuman;
      final game = StumbleBrawlGame(
        humanSkins: [0],
        botSkins: [1,2,3],
        onWinner: (w, h) { winner = w; isHuman = h; },
        onGameOver: () {},
      );
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (game.players.length == 4) break;
      }
      // kill all bots
      for (var p in game.players.where((p) => !p.isHuman)) {
        p.isAlive = false;
      }
      // trigger update to check win
      await tester.pump(const Duration(milliseconds: 100));
      game.update(0.1);
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.isGameOver, true);
      expect(winner, 'Você');
      expect(isHuman, true);
      // let delayed onGameOver timer fire to avoid pending timer
      await tester.pump(const Duration(milliseconds: 1000));
    });

    testWidgets('restart resets', (tester) async {
      final game = StumbleBrawlGame(humanSkins: [0], botSkins: [1,2,3]);
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (game.players.isNotEmpty) break;
      }
      game.players.first.damage = 80;
      game.elapsed = 50;
      game.restart();
      expect(game.elapsed, 0);
      expect(game.isGameOver, false);
      expect(game.players.first.damage, 0);
    });

    testWidgets('human input via setHumanInputSingle', (tester) async {
      final game = StumbleBrawlGame(humanSkins: [0], botSkins: [1,2,3]);
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (game.players.isNotEmpty) break;
      }
      game.setHumanInputSingle(x: 1, jump: true, jumpPressed: true);
      expect(game.humanInputs[0].x, 1);
      expect(game.humanInputs[0].jump, true);
      game.setHumanInputSingle(x: -1);
      expect(game.humanInputs[0].x, -1);
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
