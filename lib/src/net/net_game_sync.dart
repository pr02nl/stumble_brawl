import 'dart:async';
import 'dart:convert';
import '../game/stumble_brawl_game.dart';
import 'webrtc_manager.dart';

// Sync host authoritative 20Hz — Fase 3
// Host envia snapshot, clients enviam InputState via DataChannel (stub in-memory)
// Futuro: substituir InMemoryWebRTCManager por FlutterWebRTCManager real

class NetGameSync {
  final StumbleBrawlGame game;
  final WebRTCManager webrtc;
  final bool isHost;
  Timer? _sendTimer;
  StreamSubscription? _sub;

  NetGameSync({required this.game, required this.webrtc, required this.isHost});

  void start() {
    if (isHost) {
      // host broadcast snapshot 20Hz
      _sendTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        final snap = {
          't': game.elapsed,
          'pos': game.players.map((p) => {'x': p.position.x, 'y': p.position.y, 'dmg': p.damage, 'alive': p.isAlive}).toList(),
          'powerUps': game.powerUps.map((pu) => {'x': pu.position.x, 'y': pu.position.y, 'type': pu.type.index}).toList(),
        };
        webrtc.sendInput({'type': 'snapshot', 'data': snap});
      });
      _sub = webrtc.onMessage.listen((msg) {
        if (msg['type'] == 'input' && msg['player'] is int) {
          final idx = msg['player'] as int;
          final x = (msg['x'] as num?)?.toDouble();
          final jump = msg['jump'] as bool?;
          final punch = msg['punch'] as bool?;
          if (idx >= 0 && idx < game.humanInputs.length) {
            game.setHumanInput(idx, x: x, jump: jump, punch: punch, jumpPressed: msg['jumpPressed']==true, punchPressed: msg['punchPressed']==true);
          }
        }
      });
    } else {
      // client envia input 20Hz e aplica snapshots do host
      _sendTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        for (int i = 0; i < game.humanInputs.length; i++) {
          final inp = game.humanInputs[i];
          webrtc.sendInput({'type': 'input', 'player': i, 'x': inp.x, 'jump': inp.jump, 'punch': inp.punch, 'jumpPressed': inp.jumpPressedThisFrame, 'punchPressed': inp.punchPressedThisFrame});
        }
      });
      _sub = webrtc.onMessage.listen((msg) {
        if (msg['type'] == 'snapshot' && msg['data'] is Map) {
          final data = msg['data'] as Map;
          final posList = data['pos'] as List?;
          if (posList == null) return;
          for (int i = 0; i < posList.length && i < game.players.length; i++) {
            final p = posList[i] as Map;
            game.players[i].position.setValues(p['x'] as double, p['y'] as double);
            game.players[i].damage = (p['dmg'] as num).toDouble();
            game.players[i].isAlive = p['alive'] as bool;
          }
        }
      });
    }
  }

  Future<void> dispose() async {
    _sendTimer?.cancel();
    await _sub?.cancel();
  }

  Map<String, dynamic> toJsonSnapshot() => {'t': game.elapsed, 'players': game.players.length};
  static Map<String, dynamic> parseSnapshot(String jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>;
}
