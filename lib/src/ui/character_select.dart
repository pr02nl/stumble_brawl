import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/game_state.dart';
import '../game/skin_manager.dart';

class CharacterSelect extends ConsumerStatefulWidget {
  const CharacterSelect({super.key});

  @override
  ConsumerState<CharacterSelect> createState() => _CharacterSelectState();
}

class _CharacterSelectState extends ConsumerState<CharacterSelect> {
  final SkinManager skinMgr = SkinManager();
  bool loaded = false;
  int editingPlayer = 0;

  @override
  void initState() {
    super.initState();
    skinMgr.load().then((_) => setState(() => loaded = true));
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final state = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6BB6FF), Color(0xFF4A90E2)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text('ESCOLHA SEU TIME', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              // Seletor de quantidade de humanos (TV)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('JOGADORES LOCAIS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(width: 8),
                    for (int c = 1; c <= 4; c++)
                      GestureDetector(
                        onTap: () => notifier.setHumanCount(c),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: state.humanCount == c ? const Color(0xFF4CD964) : Colors.white,
                            border: Border.all(color: const Color(0xFF4A90E2)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('$c', style: TextStyle(fontWeight: FontWeight.bold, color: state.humanCount == c ? Colors.white : const Color(0xFF4A90E2))),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.humanCount == 1 ? '1 humano + ${4 - state.humanCount} bots • Conecte controles na TV para + jogadores' : '${state.humanCount} humanos + ${4 - state.humanCount} bots • Cada controle = 1 jogador',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              const SizedBox(height: 12),
              // Abas por jogador humano
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.humanCount,
                  itemBuilder: (c, i) {
                    final sel = editingPlayer == i;
                    final skinId = state.humanSkins.length > i ? state.humanSkins[i] : 0;
                    final skin = allSkins.firstWhere((s) => s.id == skinId, orElse: () => allSkins[0]);
                    return GestureDetector(
                      onTap: () => setState(() => editingPlayer = i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? Colors.white : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: skin.color, width: 2),
                        ),
                        child: Row(children: [
                          Text(skin.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(i == 0 ? 'VOCÊ' : 'P${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: sel ? Colors.black87 : Colors.white, fontSize: 12)),
                          if (sel) const Icon(Icons.edit, size: 14),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.95),
                  itemCount: allSkins.length,
                  itemBuilder: (c, i) {
                    final skin = allSkins[i];
                    final unlocked = skinMgr.isUnlocked(skin.id);
                    final isSelectedForEditing = state.humanSkins.length > editingPlayer && state.humanSkins[editingPlayer] == skin.id;
                    return GestureDetector(
                      onTap: () {
                        if (!unlocked) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${skin.name} bloqueada! Vá na LOJA (${skin.price} moedas)')));
                          return;
                        }
                        final skins = List<int>.from(state.humanSkins);
                        skins[editingPlayer] = skin.id;
                        notifier.setHumanSkins(skins);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: unlocked ? skin.color : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelectedForEditing ? Colors.white : Colors.white30, width: isSelectedForEditing ? 4 : 1.5),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: isSelectedForEditing ? 12 : 4, offset: const Offset(0, 4))],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                                    child: Center(child: Text(skin.emoji, style: TextStyle(fontSize: unlocked ? 28 : 22))),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(skin.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                  if (!unlocked) Text('🔒 ${skin.price}', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            if (isSelectedForEditing) const Positioned(top: 8, right: 8, child: Icon(Icons.check_circle, color: Colors.white, size: 22)),
                            if (!unlocked) const Positioned(top: 8, right: 8, child: Icon(Icons.lock, color: Colors.white70, size: 16)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () => notifier.toMenu(),
                        child: const Text('VOLTAR', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CD964), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 6),
                        onPressed: () => notifier.toPlaying(),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('BORA LUTAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)), SizedBox(width: 6), Icon(Icons.bolt, color: Colors.white)]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
