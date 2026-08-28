import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/game_state.dart';
import '../game/ranking.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  final RankingManager ranking = RankingManager();
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    ranking.load().then((_) => setState(() => loaded = true));
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: const Text('RANKING', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFFF9500),
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => ref.read(gameStateProvider.notifier).toMenu()),
        actions: [IconButton(icon: const Icon(Icons.delete), onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (c)=> AlertDialog(title: const Text('Limpar ranking?'), content: const Text('Isso apaga vitórias e histórico.'), actions: [TextButton(onPressed: ()=> Navigator.pop(c,false), child: const Text('Cancelar')), TextButton(onPressed: ()=> Navigator.pop(c,true), child: const Text('Limpar'))]));
          if (ok==true) { await ranking.reset(); setState(() {}); }
        })],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFCC00), Color(0xFFFF9500)])),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _StatCard(label: 'VITÓRIAS', value: '${ranking.totalWins}', color: const Color(0xFF4CD964), icon: Icons.emoji_events),
                  const SizedBox(width: 12),
                  _StatCard(label: 'PARTIDAS', value: '${ranking.totalGames}', color: const Color(0xFF4A90E2), icon: Icons.sports_esports),
                  const SizedBox(width: 12),
                  _StatCard(label: 'TAXA', value: '${(ranking.winRate * 100).toStringAsFixed(0)}%', color: const Color(0xFFFF3B30), icon: Icons.trending_up),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Melhor dano em vitória:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(ranking.bestDamage == 999 ? '--' : '${ranking.bestDamage}%', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4CD964))),
                ]),
              ),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft, child: Text('HISTÓRICO (últimas 20)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black38, blurRadius: 4)]))),
              const SizedBox(height: 8),
              Expanded(
                child: ranking.history.isEmpty
                    ? const Center(child: Text('Nenhuma partida ainda.\nVença para aparecer aqui!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)))
                    : ListView.builder(
                        itemCount: ranking.history.length,
                        itemBuilder: (c, i) {
                          final e = ranking.history[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                            child: Row(
                              children: [
                                Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFFFD700), shape: BoxShape.circle), child: Center(child: Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.playerName, style: const TextStyle(fontWeight: FontWeight.bold)), Text('${e.lastWin.day}/${e.lastWin.month} ${e.lastWin.hour}:${e.lastWin.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: Colors.black54))])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${e.bestDamage}% dano', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A90E2))), const Text('VITÓRIA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF4CD964)))]),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
        child: Column(children: [Icon(icon, color: color), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54))]),
      ),
    );
  }
}
