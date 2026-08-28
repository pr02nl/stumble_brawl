import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stumble_brawl/src/game/game_state.dart';

void main() {
  group('GameState', () {
    test('initial', () {
      const s = GameState();
      expect(s.screen, AppScreen.menu);
      expect(s.selectedColorIndex, 0);
      expect(s.humanCount, 1);
      expect(s.humanSkins, [0]);
    });

    test('copyWith', () {
      const s = GameState();
      final c = s.copyWith(screen: AppScreen.playing, humanCount: 4, winnerName: 'Você');
      expect(c.screen, AppScreen.playing);
      expect(c.humanCount, 4);
      expect(c.winnerName, 'Você');
      expect(c.selectedColorIndex, 0);
    });
  });

  group('GameStateNotifier', () {
    late ProviderContainer container;
    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('toMenu/CharacterSelect/Shop/Ranking/Playing/GameOver', () {
      final n = container.read(gameStateProvider.notifier);
      n.toCharacterSelect();
      expect(container.read(gameStateProvider).screen, AppScreen.characterSelect);
      n.toShop();
      expect(container.read(gameStateProvider).screen, AppScreen.shop);
      n.toRanking();
      expect(container.read(gameStateProvider).screen, AppScreen.ranking);
      n.toPlaying();
      expect(container.read(gameStateProvider).screen, AppScreen.playing);
      n.toGameOver('Você', isHuman: true);
      expect(container.read(gameStateProvider).screen, AppScreen.gameOver);
      expect(container.read(gameStateProvider).winnerName, 'Você');
      expect(container.read(gameStateProvider).winnerIsHuman, true);
      n.toMenu();
      expect(container.read(gameStateProvider).screen, AppScreen.menu);
      expect(container.read(gameStateProvider).winnerName, null);
    });

    test('selectColor updates humanSkins[0]', () {
      final n = container.read(gameStateProvider.notifier);
      n.selectColor(3);
      expect(container.read(gameStateProvider).selectedColorIndex, 3);
      expect(container.read(gameStateProvider).humanSkins[0], 3);
    });

    test('setHumanSkins', () {
      final n = container.read(gameStateProvider.notifier);
      n.setHumanSkins([2, 4]);
      expect(container.read(gameStateProvider).humanSkins, [2, 4]);
      expect(container.read(gameStateProvider).selectedColorIndex, 2);
      n.setHumanSkins([]);
      expect(container.read(gameStateProvider).selectedColorIndex, 0);
    });

    test('setHumanCount 1-4 clamp', () {
      final n = container.read(gameStateProvider.notifier);
      n.setHumanCount(1);
      expect(container.read(gameStateProvider).humanCount, 1);
      expect(container.read(gameStateProvider).humanSkins.length, 1);
      n.setHumanCount(4);
      expect(container.read(gameStateProvider).humanCount, 4);
      expect(container.read(gameStateProvider).humanSkins.length, 4);
      n.setHumanCount(10);
      expect(container.read(gameStateProvider).humanCount, 4);
      n.setHumanCount(0);
      expect(container.read(gameStateProvider).humanCount, 1);
      // shrink
      n.setHumanCount(2);
      expect(container.read(gameStateProvider).humanSkins.length, 2);
    });

    test('nextRound', () {
      final n = container.read(gameStateProvider.notifier);
      expect(container.read(gameStateProvider).round, 1);
      n.nextRound();
      expect(container.read(gameStateProvider).round, 2);
    });

    test('toPaused', () {
      final n = container.read(gameStateProvider.notifier);
      n.toPaused();
      expect(container.read(gameStateProvider).screen, AppScreen.paused);
    });
  });

  test('playerColors 6 entries', () {
    expect(playerColors.length, 6);
  });
}
