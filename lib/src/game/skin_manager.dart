import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Skin {
  final int id;
  final String name;
  final Color color;
  final Color secondary;
  final String emoji;
  final int price; // 0 = gratis
  final bool isPremium;

  const Skin({
    required this.id,
    required this.name,
    required this.color,
    required this.secondary,
    required this.emoji,
    this.price = 0,
    this.isPremium = false,
  });
}

final allSkins = [
  Skin(id: 0, name: 'Ciano', color: Color(0xFF00D1FF), secondary: Color(0xFF0097B2), emoji: '💧'),
  Skin(id: 1, name: 'Fogo', color: Color(0xFFFF3B30), secondary: Color(0xFFB71C1C), emoji: '🔥'),
  Skin(id: 2, name: 'Sol', color: Color(0xFFFFCC00), secondary: Color(0xFFFF9800), emoji: '⚡'),
  Skin(id: 3, name: 'Floresta', color: Color(0xFF4CD964), secondary: Color(0xFF2E7D32), emoji: '🌿'),
  Skin(id: 4, name: 'Neon', color: Color(0xFFFF2D92), secondary: Color(0xFF880E4F), emoji: '💖'),
  Skin(id: 5, name: 'Void', color: Color(0xFF9D4EDD), secondary: Color(0xFF4A148C), emoji: '🔮'),
  Skin(id: 6, name: 'Ouro', color: Color(0xFFFFD700), secondary: Color(0xFFFF6F00), emoji: '👑', price: 50, isPremium: true),
  Skin(id: 7, name: 'Gelo', color: Color(0xFFB3E5FC), secondary: Color(0xFF0288D1), emoji: '❄️', price: 80, isPremium: true),
  Skin(id: 8, name: 'Lava', color: Color(0xFFFF5722), secondary: Color(0xFF3E2723), emoji: '🌋', price: 100, isPremium: true),
  Skin(id: 9, name: 'Galaxy', color: Color(0xFF673AB7), secondary: Color(0xFF000000), emoji: '🌌', price: 150, isPremium: true),
  Skin(id: 10, name: 'Tóxico', color: Color(0xFF76FF03), secondary: Color(0xFF1B5E20), emoji: '☢️', price: 120, isPremium: true),
  Skin(id: 11, name: 'Ruby', color: Color(0xFFE91E63), secondary: Color(0xFFAD1457), emoji: '💎', price: 200, isPremium: true),
];

class SkinManager {
  static const _kCoins = 'coins';
  static const _kUnlocked = 'unlocked_skins';
  static const _kSelected = 'selected_skin';

  int coins = 0;
  Set<int> unlocked = {0, 1, 2, 3, 4, 5}; // gratis liberadas
  int selectedId = 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    coins = prefs.getInt(_kCoins) ?? 0;
    final list = prefs.getStringList(_kUnlocked);
    if (list != null) {
      unlocked = list.map((e) => int.parse(e)).toSet();
      // garante gratis sempre
      unlocked.addAll([0, 1, 2, 3, 4, 5]);
    }
    selectedId = prefs.getInt(_kSelected) ?? 0;
    if (!unlocked.contains(selectedId)) selectedId = 0;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCoins, coins);
    await prefs.setStringList(_kUnlocked, unlocked.map((e) => e.toString()).toList());
    await prefs.setInt(_kSelected, selectedId);
  }

  bool isUnlocked(int id) => unlocked.contains(id);

  Future<bool> buy(int id) async {
    final skin = allSkins.firstWhere((s) => s.id == id);
    if (isUnlocked(id)) return true;
    if (coins < skin.price) return false;
    coins -= skin.price;
    unlocked.add(id);
    await _save();
    return true;
  }

  Future<void> select(int id) async {
    if (!isUnlocked(id)) return;
    selectedId = id;
    await _save();
  }

  Future<void> addCoins(int amount) async {
    coins += amount;
    await _save();
  }

  Skin get selected => allSkins.firstWhere((s) => s.id == selectedId, orElse: () => allSkins[0]);
  Skin byId(int id) => allSkins.firstWhere((s) => s.id == id, orElse: () => allSkins[0]);
}
