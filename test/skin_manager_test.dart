import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stumble_brawl/src/game/skin_manager.dart';

void main() {
  group('SkinManager', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('allSkins 12 entries', () {
      expect(allSkins.length, 12);
      expect(allSkins[0].id, 0);
      expect(allSkins[11].id, 11);
      expect(allSkins.where((s) => s.price == 0).length, 6);
      expect(allSkins.where((s) => s.isPremium).length, 6);
    });

    test('initial load gratis unlocked', () async {
      final m = SkinManager();
      await m.load();
      expect(m.coins, 0);
      expect(m.unlocked, containsAll([0, 1, 2, 3, 4, 5]));
      expect(m.selectedId, 0);
      expect(m.isUnlocked(0), true);
      expect(m.isUnlocked(6), false);
    });

    test('addCoins and save', () async {
      SharedPreferences.setMockInitialValues({});
      final m = SkinManager();
      await m.load();
      await m.addCoins(100);
      expect(m.coins, 100);
      // reload
      final m2 = SkinManager();
      await m2.load();
      expect(m2.coins, 100);
    });

    test('buy fails without coins', () async {
      final m = SkinManager();
      await m.load();
      final ok = await m.buy(6); // Ouro 50
      expect(ok, false);
      expect(m.isUnlocked(6), false);
      expect(m.coins, 0);
    });

    test('buy succeeds with enough coins', () async {
      final m = SkinManager();
      await m.load();
      await m.addCoins(100);
      final ok = await m.buy(6);
      expect(ok, true);
      expect(m.isUnlocked(6), true);
      expect(m.coins, 50);
    });

    test('buy premium and select', () async {
      final m = SkinManager();
      await m.load();
      await m.addCoins(200);
      await m.buy(9); // Galaxy 150
      await m.select(9);
      expect(m.selectedId, 9);
      expect(m.selected.name, 'Galaxy');
      final m2 = SkinManager();
      await m2.load();
      expect(m2.selectedId, 9);
    });

    test('select locked fails', () async {
      final m = SkinManager();
      await m.load();
      await m.select(6);
      expect(m.selectedId, 0); // stays 0
    });

    test('load ensures gratis even if stored without', () async {
      SharedPreferences.setMockInitialValues({
        'coins': 10,
        'unlocked_skins': ['6', '7'],
        'selected_skin': 6,
      });
      final m = SkinManager();
      await m.load();
      expect(m.unlocked, contains(0));
      expect(m.unlocked, contains(6));
      expect(m.selectedId, 6);
    });

    test('byId fallback', () {
      final m = SkinManager();
      expect(m.byId(0).name, 'Ciano');
      expect(m.byId(999).id, 0); // fallback to 0
      expect(m.selected.id, 0);
    });

    test('buy already unlocked returns true', () async {
      final m = SkinManager();
      await m.load();
      final ok = await m.buy(0);
      expect(ok, true);
    });
  });
}
