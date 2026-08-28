import 'package:share_plus/share_plus.dart';
import '../game/stumble_brawl_game.dart';

class ClipExporter {
  static Future<void> shareResult(StumbleBrawlGame game, String winner) async {
    final arena = game.arenaId;
    final time = game.elapsed.toStringAsFixed(1);
    final alive = game.players.where((p) => p.isAlive).length;
    final dmg = game.players.map((p) => '${p.name}:${p.damage.toInt()}%').join(', ');
    final text = '🏆 Stumble Brawl — Vencedor: $winner | Arena: $arena | Tempo: ${time}s | Vivos: $alive | Dano: $dmg — Jogue em stumble_brawl!';
    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: 'Stumble Brawl — Meu clipe!'));
    } catch (_) {}
  }

  static Future<void> shareText(String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {}
  }
}
