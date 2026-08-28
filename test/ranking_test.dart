import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stumble_brawl/src/game/ranking.dart';

void main() {
  group('RankingEntry', () {
    test('toJson/fromJson', () {
      final e = RankingEntry(playerName: 'Você', wins: 1, games: 1, bestDamage: 23, lastWin: DateTime.utc(2026, 8, 27, 12, 0, 0));
      final j = e.toJson();
      final r = RankingEntry.fromJson(j);
      expect(r.playerName, 'Você');
      expect(r.bestDamage, 23);
      expect(r.lastWin, DateTime.utc(2026, 8, 27, 12, 0, 0));
    });
  });

  group('RankingManager', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('initial values', () async {
      final m = RankingManager();
      await m.load();
      expect(m.totalWins, 0);
      expect(m.totalGames, 0);
      expect(m.bestDamage, 999);
      expect(m.history, isEmpty);
      expect(m.winRate, 0);
    });

    test('record human win', () async {
      final m = RankingManager();
      await m.load();
      await m.recordGame(winner: 'Você', winnerDamage: 30, isHumanWin: true);
      expect(m.totalWins, 1);
      expect(m.totalGames, 1);
      expect(m.bestDamage, 30);
      expect(m.history.length, 1);
      expect(m.winRate, 1.0);
    });

    test('record bot win does not increase wins', () async {
      final m = RankingManager();
      await m.load();
      await m.recordGame(winner: 'Bot 1', winnerDamage: 10, isHumanWin: false);
      expect(m.totalWins, 0);
      expect(m.totalGames, 1);
      expect(m.history, isEmpty);
      expect(m.winRate, 0);
    });

    test('bestDamage keeps minimum', () async {
      final m = RankingManager();
      await m.load();
      await m.recordGame(winner: 'Você', winnerDamage: 50, isHumanWin: true);
      await m.recordGame(winner: 'Você', winnerDamage: 20, isHumanWin: true);
      await m.recordGame(winner: 'Você', winnerDamage: 80, isHumanWin: true);
      expect(m.bestDamage, 20);
      expect(m.totalWins, 3);
    });

    test('history limited 20', () async {
      final m = RankingManager();
      await m.load();
      for (int i = 0; i < 25; i++) {
        await m.recordGame(winner: 'Você', winnerDamage: i, isHumanWin: true);
      }
      expect(m.history.length, 20);
      expect(m.totalGames, 25);
    });

    test('load history parsing', () async {
      SharedPreferences.setMockInitialValues({
        'rank_wins': 2,
        'rank_games': 5,
        'rank_best': 15,
        'rank_history': [
          'Você|1|1|10|2026-08-27T12:00:00.000',
          'P2|1|1|20|2026-08-27T11:00:00.000',
          'bad|format',
        ],
      });
      final m = RankingManager();
      await m.load();
      expect(m.totalWins, 2);
      expect(m.totalGames, 5);
      expect(m.bestDamage, 15);
      expect(m.history.length, 2);
      expect(m.history.first.playerName, 'Você');
    });

    test('reset clears', () async {
      final m = RankingManager();
      await m.load();
      await m.recordGame(winner: 'Você', winnerDamage: 10, isHumanWin: true);
      await m.reset();
      expect(m.totalWins, 0);
      expect(m.totalGames, 0);
      expect(m.bestDamage, 999);
      expect(m.history, isEmpty);
      final m2 = RankingManager();
      await m2.load();
      expect(m2.totalWins, 0);
    });

    test('winRate calc', () async {
      final m = RankingManager();
      await m.load();
      await m.recordGame(winner: 'Você', winnerDamage: 10, isHumanWin: true);
      await m.recordGame(winner: 'Bot 1', winnerDamage: 10, isHumanWin: false);
      expect(m.winRate, 0.5);
    });
  });
}
