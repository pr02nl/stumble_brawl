import 'package:shared_preferences/shared_preferences.dart';

class RankingEntry {
  final String playerName;
  final int wins;
  final int games;
  final int bestDamage; // menor dano em vitória
  final DateTime lastWin;

  RankingEntry({required this.playerName, required this.wins, required this.games, required this.bestDamage, required this.lastWin});

  Map<String, dynamic> toJson() => {
        'name': playerName,
        'wins': wins,
        'games': games,
        'best': bestDamage,
        'last': lastWin.toIso8601String(),
      };

  static RankingEntry fromJson(Map<String, dynamic> j) => RankingEntry(
        playerName: j['name'] as String,
        wins: j['wins'] as int,
        games: j['games'] as int,
        bestDamage: j['best'] as int,
        lastWin: DateTime.parse(j['last'] as String),
      );
}

class RankingManager {
  static const _kWins = 'rank_wins';
  static const _kGames = 'rank_games';
  static const _kBest = 'rank_best';
  static const _kLast = 'rank_last';
  static const _kHistory = 'rank_history';

  int totalWins = 0;
  int totalGames = 0;
  int bestDamage = 999;
  List<RankingEntry> history = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    totalWins = p.getInt(_kWins) ?? 0;
    totalGames = p.getInt(_kGames) ?? 0;
    bestDamage = p.getInt(_kBest) ?? 999;
    final hist = p.getStringList(_kHistory);
    if (hist != null) {
      history = hist.map((e) {
        final parts = e.split('|');
        if (parts.length < 5) return null;
        try {
          return RankingEntry(
            playerName: parts[0],
            wins: int.parse(parts[1]),
            games: int.parse(parts[2]),
            bestDamage: int.parse(parts[3]),
            lastWin: DateTime.parse(parts[4]),
          );
        } catch (_) { return null; }
      }).whereType<RankingEntry>().toList();
    }
  }

  Future<void> recordGame({required String winner, required int winnerDamage, required bool isHumanWin}) async {
    final p = await SharedPreferences.getInstance();
    totalGames++;
    await p.setInt(_kGames, totalGames);

    if (isHumanWin) {
      totalWins++;
      if (winnerDamage < bestDamage) {
        bestDamage = winnerDamage;
        await p.setInt(_kBest, bestDamage);
      }
      await p.setInt(_kWins, totalWins);
      // histórico: adiciona entrada para winner
      history.insert(0, RankingEntry(playerName: winner, wins: 1, games: 1, bestDamage: winnerDamage, lastWin: DateTime.now()));
      if (history.length > 20) history = history.sublist(0, 20);
      await p.setStringList(_kHistory, history.map((e) => '${e.playerName}|${e.wins}|${e.games}|${e.bestDamage}|${e.lastWin.toIso8601String()}').toList());
      await p.setString(_kLast, DateTime.now().toIso8601String());
    }
  }

  double get winRate => totalGames == 0 ? 0 : totalWins / totalGames;

  Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kWins);
    await p.remove(_kGames);
    await p.remove(_kBest);
    await p.remove(_kHistory);
    await p.remove(_kLast);
    totalWins = 0;
    totalGames = 0;
    bestDamage = 999;
    history.clear();
  }
}
