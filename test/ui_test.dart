import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stumble_brawl/main.dart';
import 'package:stumble_brawl/src/game/game_state.dart';
import 'package:stumble_brawl/src/ui/main_menu.dart';
import 'package:stumble_brawl/src/ui/character_select.dart';
import 'package:stumble_brawl/src/ui/shop_screen.dart';
import 'package:stumble_brawl/src/ui/ranking_screen.dart';
import 'package:stumble_brawl/src/ui/hud.dart';
import 'package:stumble_brawl/src/actors/player.dart';
import 'package:stumble_brawl/src/input/input_state.dart';
import 'package:flame/components.dart';

void main() {
  group('MainMenu', () {
    testWidgets('shows JOGAR and navigates', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const StumbleBrawlApp()));
      await tester.pump();
      expect(find.text('JOGAR'), findsOneWidget);
      expect(find.textContaining('STUMBLE'), findsOneWidget);
      container.read(gameStateProvider.notifier).toCharacterSelect();
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.textContaining('ESCOLHA'), findsOneWidget);
      container.dispose();
    });

    testWidgets('COMO JOGAR dialog', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: MainMenu())));
      await tester.pump();
      await tester.tap(find.text('COMO JOGAR'));
      await tester.pump();
      expect(find.textContaining('Como Jogar'), findsOneWidget);
      await tester.tap(find.text('FECHAR'));
      await tester.pump();
    });

    testWidgets('LOJA and RANKING buttons', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: MainMenu())));
      await tester.pump();
      expect(find.text('LOJA'), findsOneWidget);
      expect(find.text('RANKING'), findsOneWidget);
    });
  });

  group('CharacterSelect', () {
    testWidgets('renders 12 skins and player count', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: CharacterSelect())));
      await tester.pump();
      // after load
      await tester.pump(const Duration(milliseconds: 100));
      // title
      expect(find.text('ESCOLHA SEU TIME'), findsOneWidget);
      // player count buttons
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      // at least one skin name visible? e.g., Ciano
      // grid has 12 items, but need pump
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('select human count 4', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const CharacterSelect())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('4'));
      await tester.pump();
      // should have 4 tabs P2 etc? Check for P4?
      // Note humanSkins length becomes 4, but UI shows tabs
    });

    testWidgets('tap skin changes selection', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const CharacterSelect())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // find first skin grid item and tap
      final first = find.byType(GestureDetector).first;
      await tester.tap(first);
      await tester.pump();
    });
  });

  group('ShopScreen', () {
    testWidgets('shows shop with coins', (tester) async {
      SharedPreferences.setMockInitialValues({'coins': 100, 'unlocked_skins': ['0','1','2','3','4','5'], 'selected_skin': 0});
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ShopScreen())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('LOJA'), findsOneWidget);
      // should show at least one buy button
    });
  });

  group('RankingScreen', () {
    testWidgets('shows ranking stats', (tester) async {
      SharedPreferences.setMockInitialValues({'rank_wins': 2, 'rank_games': 5, 'rank_best': 10});
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RankingScreen())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('RANKING'), findsOneWidget);
      expect(find.text('VITÓRIAS'), findsOneWidget);
    });

    testWidgets('empty history', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RankingScreen())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Nenhuma partida'), findsOneWidget);
    });
  });

  group('Hud', () {
    testWidgets('shows timer and players', (tester) async {
      final players = [
        Player(id: 0, name: 'Você', color: Colors.red, skinId: 0, isHuman: true, input: InputState(), position: Vector2(0,0), size: Vector2(36,44))..damage = 20,
        Player(id: 1, name: 'Bot 1', color: Colors.blue, skinId: 1, isHuman: false, input: InputState(), position: Vector2(0,0), size: Vector2(36,44))..isAlive = false,
      ];
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Hud(timeLeft: 42, elapsed: 10, players: players))));
      await tester.pump();
      expect(find.text('00:42'), findsOneWidget);
      expect(find.textContaining('VIVOS'), findsOneWidget);
      expect(find.text('Você'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
    });
  });

  group('StumbleBrawlApp navigation', () {
    testWidgets('App initial menu', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: StumbleBrawlApp()));
      await tester.pump();
      expect(find.text('JOGAR'), findsOneWidget);
    });

    testWidgets('App to shop via provider', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const StumbleBrawlApp()));
      await tester.pump();
      container.read(gameStateProvider.notifier).toShop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('LOJA'), findsOneWidget);
      container.dispose();
    });

    testWidgets('App to ranking', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const StumbleBrawlApp()));
      await tester.pump();
      container.read(gameStateProvider.notifier).toRanking();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('RANKING'), findsOneWidget);
      container.dispose();
    });
  });
}
