import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/game_state.dart';
import '../net/signaling_manager.dart';

// Lobby stub Fase 3 — UI para WebRTC sem lógica completa ainda
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});
  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final signaling = SignalingManager();
  String? roomCode;
  final codeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ONLINE LOBBY (WIP)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('WebRTC P2P — Fase 3 em construção', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () async { final c = await signaling.createRoom(); setState(()=> roomCode=c); }, child: Text(roomCode == null ? 'CRIAR SALA' : 'SALA: $roomCode')),
          const SizedBox(height: 12),
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Código sala 6 letras', border: OutlineInputBorder())),
          ElevatedButton(onPressed: () async { final ok = await signaling.joinRoom(codeCtrl.text); if(ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrou (stub)'))); }, child: const Text('ENTRAR')),
          const SizedBox(height: 12),
          const Text('TODO: flutter_webrtc DataChannel + Firestore signaling', style: TextStyle(color: Colors.black54, fontSize: 11)),
          const Spacer(),
          OutlinedButton(onPressed: ()=> ref.read(gameStateProvider.notifier).toMenu(), child: const Text('VOLTAR MENU')),
        ]),
      ),
    );
  }
}
