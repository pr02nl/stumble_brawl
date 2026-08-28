import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stumble_brawl/src/audio/audio_manager.dart';
import 'package:stumble_brawl/src/game/stumble_brawl_game.dart';

void main() {
  testWidgets('debug F', (tester) async {
    audioManager.setSfx(false);
    audioManager.setMusic(false);
    final game = StumbleBrawlGame(humanSkins: [0], botSkins: [1, 2, 3]);
    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    for (int i = 0; i < 20; i++) {
      await tester.pump(Duration(milliseconds: 200));
      if (game.players.isNotEmpty) break;
    }
    if (kDebugMode) {
      print('before F keys: ${HardwareKeyboard.instance.logicalKeysPressed}');
    }
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.pump(Duration(milliseconds: 16));
    if (kDebugMode) {
      print(
        'after F down keys: ${HardwareKeyboard.instance.logicalKeysPressed}',
      );
      print(
        'humanInputs punch: ${game.humanInputs[0].punch} punchPressed: ${game.humanInputs[0].punchPressedThisFrame}',
      );
      print('game players: ${game.players.length}');
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.pump(Duration(milliseconds: 16));
    if (kDebugMode) {
      print('after F up keys: ${HardwareKeyboard.instance.logicalKeysPressed}');
      print('punch: ${game.humanInputs[0].punch}');
    }
  });
}
