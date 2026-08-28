import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_manager.dart';
import '../game/game_state.dart';
import '../game/skin_manager.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final SkinManager manager = SkinManager();
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    manager.load().then((_) => setState(() => loaded = true));
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LOJA DE SKINS',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFF9D4EDD),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ref.read(gameStateProvider.notifier).toMenu(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  size: 18,
                  color: Colors.black87,
                ),
                const SizedBox(width: 4),
                Text(
                  '${manager.coins}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB388FF), Color(0xFF7C4DFF)],
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: allSkins.length,
          itemBuilder: (c, i) {
            final skin = allSkins[i];
            final unlocked = manager.isUnlocked(skin.id);
            final selected = manager.selectedId == skin.id;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? const Color(0xFF4CD964) : Colors.white24,
                  width: selected ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: skin.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: skin.secondary, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        skin.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    skin.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (skin.price > 0 && !unlocked)
                    Text(
                      '${skin.price} moedas',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  else if (unlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CD964),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        selected ? 'SELECIONADO' : 'DESBLOQUEADO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'GRÁTIS',
                      style: TextStyle(
                        color: Color(0xFF4CD964),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: unlocked
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selected
                                  ? const Color(0xFF4CD964)
                                  : const Color(0xFF4A90E2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              await manager.select(skin.id);
                              setState(() {});
                              audioManager.playPowerUp();
                              // atualiza estado global para refletir
                              ref
                                  .read(gameStateProvider.notifier)
                                  .selectColor(skin.id);
                            },
                            child: Text(
                              selected ? '✓' : 'USAR',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9800),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              final ok = await manager.buy(skin.id);
                              setState(() {});
                              if (!context.mounted) {
                                return;
                              }
                              if (ok) {
                                audioManager.playWin();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Desbloqueou ${skin.name}!'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Moedas insuficientes! Vença partidas para ganhar +20 moedas',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'COMPRAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
