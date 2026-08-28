import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_options.dart';
import 'src/game/game_state.dart';
import 'src/ui/main_menu.dart';
import 'src/ui/character_select.dart';
import 'src/ui/game_screen.dart';
import 'src/ui/shop_screen.dart';
import 'src/ui/ranking_screen.dart';
import 'src/ui/lobby_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  if (!supabaseUrl.contains('placeholder')) {
    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    } catch (_) {}
  }

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
