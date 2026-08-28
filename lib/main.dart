import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/game/game_state.dart';
import 'src/ui/main_menu.dart';
import 'src/ui/character_select.dart';
import 'src/ui/game_screen.dart';
import 'src/ui/shop_screen.dart';
import 'src/ui/ranking_screen.dart';
import 'src/ui/lobby_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Orientação: permite ambos, mas prefere paisagem na TV
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Esconde barras para TV
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const ProviderScope(child: StumbleBrawlApp()));
}

class StumbleBrawlApp extends ConsumerWidget {
  const StumbleBrawlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    return MaterialApp(
      title: 'Stumble Brawl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90E2)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: switch (state.screen) {
        AppScreen.menu => const MainMenu(),
        AppScreen.characterSelect => const CharacterSelect(),
        AppScreen.shop => const ShopScreen(),
        AppScreen.ranking => const RankingScreen(),
        AppScreen.lobby => const LobbyScreen(),
        AppScreen.playing => const GameScreen(),
        AppScreen.gameOver => const GameScreen(),
        AppScreen.paused => const GameScreen(),
      },
    );
  }
}
