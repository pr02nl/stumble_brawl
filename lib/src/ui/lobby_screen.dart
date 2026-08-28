import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/game_state.dart';
import '../net/supabase_signaling.dart';
import '../net/supabase_webrtc_manager.dart';
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});
  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final signaling = SupabaseSignalingManager();
  String? roomCode;
  bool busy = false;
  String? status;
  final codeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ONLINE LOBBY (WIP)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(signaling.isConfigured ? 'Supabase OK — WebRTC nativo' : 'Modo stub (sem Supabase) — configure SUPABASE_URL', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (status != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(status!, style: const TextStyle(color: Color(0xFF4A90E2), fontSize: 12))),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: busy ? null : () async {
              setState(() { busy = true; status = 'Criando sala...'; });
              final c = await signaling.createRoom();
              if (!mounted) return;
              setState(() { roomCode = c; busy = false; status = 'Sala $c criada. Compartilhe o código!'; });
              // host WebRTC
              final mgr = SupabaseWebRTCManager(signaling: signaling, isHost: true);
              try { await mgr.createRoom(c); if (mounted) setState(() => status = 'Sala $c — aguardando guest (DataChannel)...'); } catch (e) { setState(() => status = 'Erro WebRTC: $e'); }
            },
            child: Text(roomCode == null ? 'CRIAR SALA' : 'SALA: $roomCode'),
          ),
          const SizedBox(height: 12),
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Código sala 6 letras', border: OutlineInputBorder())),
          ElevatedButton(
            onPressed: busy ? null : () async {
              final code = codeCtrl.text.trim().toUpperCase();
              if (code.length != 6) { setState(() => status = 'Código deve ter 6 chars'); return; }
              setState(() { busy = true; status = 'Entrando em $code...'; });
              final room = await signaling.joinRoom(code);
              if (!mounted) return;
              if (room == null) { setState(() { busy = false; status = 'Sala não encontrada'; }); return; }
              setState(() { busy = false; status = 'Entrou em $code! Conectando WebRTC...'; });
              final mgr = SupabaseWebRTCManager(signaling: signaling, isHost: false);
              try { await mgr.joinRoom(code); if (mounted) setState(() => status = 'Conectado em $code!'); } catch (e) { if (mounted) setState(() => status = 'Erro join: $e'); }
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Entrou em $code'))); 
            },
            child: const Text('ENTRAR'),
          ),
          const SizedBox(height: 12),
          const Text('Supabase Realtime em rooms + flutter_webrtc DataChannel 20Hz (linux/windows nativo)', style: TextStyle(color: Colors.black54, fontSize: 11)),
          const Spacer(),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: () => ref.read(gameStateProvider.notifier).toPlaying(), child: const Text('JOGAR ONLINE (HOST)'))),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: ()=> ref.read(gameStateProvider.notifier).toMenu(), child: const Text('VOLTAR MENU')),
          ]),
        ]),
      ),
    );
  }
}
