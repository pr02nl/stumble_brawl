import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/game_state.dart';
import '../game/skin_manager.dart';
import '../game/ranking.dart';

class MainMenu extends ConsumerStatefulWidget {
  const MainMenu({super.key});

  @override
  ConsumerState<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends ConsumerState<MainMenu> {
  final SkinManager skinMgr = SkinManager();
  final RankingManager ranking = RankingManager();
  int coins = 0;
  int wins = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await skinMgr.load();
    await ranking.load();
    if (mounted) setState(() { coins = skinMgr.coins; wins = ranking.totalWins; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF6BB6FF), Color(0xFF4A90E2)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💥', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 4),
                const Text(
                  'STUMBLE\nBRAWL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 0.9,
                    shadows: [Shadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Text('MOBILE • TV • CONTROLE • 1-4 PLAYERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF4A90E2))),
                ),
                const SizedBox(height: 12),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [const Icon(Icons.monetization_on, size: 16), const SizedBox(width: 4), Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold))]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF4CD964), borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [const Icon(Icons.emoji_events, size: 16, color: Colors.white), const SizedBox(width: 4), Text('$wins vitórias', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _MenuButton(
                  label: 'JOGAR',
                  icon: Icons.play_arrow_rounded,
                  color: const Color(0xFF4CD964),
                  onPressed: () => ref.read(gameStateProvider.notifier).toCharacterSelect(),
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 125, height: 52, child: _SmallButton(label: 'LOJA', icon: Icons.store, color: const Color(0xFF9D4EDD), onPressed: () => ref.read(gameStateProvider.notifier).toShop())),
                  const SizedBox(width: 10),
                  SizedBox(width: 125, height: 52, child: _SmallButton(label: 'RANKING', icon: Icons.leaderboard, color: const Color(0xFFFF9500), onPressed: () => ref.read(gameStateProvider.notifier).toRanking())),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: 260,
                  height: 44,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.wifi, size: 18),
                    label: const Text('ONLINE LOBBY (WIP)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => ref.read(gameStateProvider.notifier).toLobby(),
                  ),
                ),
                const SizedBox(height: 10),
                _MenuButton(
                  label: 'COMO JOGAR',
                  icon: Icons.help_outline,
                  color: const Color(0xFFFFCC00),
                  onPressed: () => _showHowToPlay(context),
                ),
                const SizedBox(height: 16),
                const Text('Até 4 humanos locais + bots • Power-ups a cada 5s!',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11)),
                const SizedBox(height: 4),
                const Text('🍌 Banana  🌀 Mola  🛡️ Escudo  🚀 Turbo',
                    style: TextStyle(color: Colors.white60, fontSize: 11)),
                const SizedBox(height: 4),
                const Text('Controle: analógico move • A pula • X soca • TV multi-controle!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 9)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Como Jogar - V1.1'),
        content: const SingleChildScrollView(
          child: Text(
            '• Mova com analógico / D-pad ou touch\n'
            '• Pulo + pulo duplo (A / botão pular)\n'
            '• Soco empurra (X / botão soco) - dano aumenta knockback!\n'
            '• Plataformas laranjas caem após 0.8s\n'
            '• Power-ups nas plataformas: 🍌 banana limpa dano, 🌀 mola super pulo, 🛡️ escudo 3s, 🚀 turbo 4s\n'
            '• Até 4 controles na TV, cada um é 1 jogador. Sem controle extra, vira bot\n'
            '• Ganhe 20 moedas por vitória humana, compre skins na LOJA\n'
            '• Caiu da arena = eliminado. Último vivo vence!',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('FECHAR'))],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _MenuButton({required this.label, required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: true,
      child: SizedBox(
        width: 260,
        height: 52,
        child: ElevatedButton.icon(
          icon: Icon(icon, color: Colors.white, size: 26),
          label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
            shadowColor: Colors.black38,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _SmallButton({required this.label, required this.icon, required this.color, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: true,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12)),
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 5),
        onPressed: onPressed,
      ),
    );
  }
}
