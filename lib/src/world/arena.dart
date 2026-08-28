import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'platform.dart';

class ArenaPlatformDef {
  final Vector2 pos;
  final Vector2 size;
  final PlatformType type;
  final Color color;
  const ArenaPlatformDef({required this.pos, required this.size, this.type = PlatformType.normal, required this.color});
}

class ArenaConfig {
  final String id;
  final String name;
  final String emoji;
  final Color bgColor;
  final List<ArenaPlatformDef> platforms;
  final List<Vector2> spawns;

  const ArenaConfig({required this.id, required this.name, required this.emoji, required this.bgColor, required this.platforms, required this.spawns});
}

final classicArena = ArenaConfig(
  id: 'classic',
  name: 'Clássica',
  emoji: '🏟️',
  bgColor: const Color(0xFF87CEEB),
  platforms: [
    ArenaPlatformDef(pos: Vector2(0, 500), size: Vector2(900, 40), type: PlatformType.normal, color: Color(0xFF5D4037)),
    ArenaPlatformDef(pos: Vector2(40, 400), size: Vector2(180, 22), color: Color(0xFF8D6E63)),
    ArenaPlatformDef(pos: Vector2(300, 380), size: Vector2(160, 22), type: PlatformType.falling, color: Color(0xFFD7A76F)),
    ArenaPlatformDef(pos: Vector2(540, 400), size: Vector2(180, 22), color: Color(0xFF8D6E63)),
    ArenaPlatformDef(pos: Vector2(740, 360), size: Vector2(120, 22), type: PlatformType.falling, color: Color(0xFFD7A76F)),
    ArenaPlatformDef(pos: Vector2(120, 300), size: Vector2(140, 22), type: PlatformType.falling, color: Color(0xFFD7A76F)),
    ArenaPlatformDef(pos: Vector2(340, 270), size: Vector2(200, 22), color: Color(0xFF8D6E63)),
    ArenaPlatformDef(pos: Vector2(620, 300), size: Vector2(140, 22), type: PlatformType.falling, color: Color(0xFFD7A76F)),
    ArenaPlatformDef(pos: Vector2(80, 190), size: Vector2(120, 22), color: Color(0xFF8D6E63)),
    ArenaPlatformDef(pos: Vector2(380, 150), size: Vector2(140, 22), type: PlatformType.falling, color: Color(0xFFFFAB40)),
    ArenaPlatformDef(pos: Vector2(600, 190), size: Vector2(120, 22), color: Color(0xFF8D6E63)),
  ],
  spawns: [Vector2(100,140), Vector2(700,140), Vector2(200,320), Vector2(600,320)],
);

final volcanoArena = ArenaConfig(
  id: 'volcano',
  name: 'Vulcão',
  emoji: '🌋',
  bgColor: Color(0xFF4E342E),
  platforms: [
    ArenaPlatformDef(pos: Vector2(0, 520), size: Vector2(900, 40), color: Color(0xFF3E2723)),
    ArenaPlatformDef(pos: Vector2(20, 420), size: Vector2(160, 22), type: PlatformType.falling, color: Color(0xFFFF5722)),
    ArenaPlatformDef(pos: Vector2(260, 380), size: Vector2(140, 22), color: Color(0xFF8D6E63)),
    ArenaPlatformDef(pos: Vector2(480, 400), size: Vector2(180, 22), type: PlatformType.falling, color: Color(0xFFFF7043)),
    ArenaPlatformDef(pos: Vector2(700, 360), size: Vector2(140, 22), color: Color(0xFF8D6E63)),
    ArenaPlatformDef(pos: Vector2(100, 300), size: Vector2(120, 22), type: PlatformType.falling, color: Color(0xFFFF5722)),
    ArenaPlatformDef(pos: Vector2(340, 260), size: Vector2(220, 22), color: Color(0xFF6D4C41)),
    ArenaPlatformDef(pos: Vector2(620, 280), size: Vector2(120, 22), type: PlatformType.falling, color: Color(0xFFFF7043)),
    ArenaPlatformDef(pos: Vector2(380, 140), size: Vector2(140, 22), type: PlatformType.falling, color: Color(0xFFFFAB40)),
  ],
  spawns: [Vector2(80,140), Vector2(720,140), Vector2(180,320), Vector2(620,330)],
);

final iceArena = ArenaConfig(
  id: 'ice',
  name: 'Gelo',
  emoji: '❄️',
  bgColor: Color(0xFFB3E5FC),
  platforms: [
    ArenaPlatformDef(pos: Vector2(0, 510), size: Vector2(900, 40), color: Color(0xFF90A4AE)),
    ArenaPlatformDef(pos: Vector2(60, 400), size: Vector2(200, 22), color: Color(0xFFB0BEC5)),
    ArenaPlatformDef(pos: Vector2(340, 360), size: Vector2(220, 22), type: PlatformType.falling, color: Color(0xFFE1F5FE)),
    ArenaPlatformDef(pos: Vector2(640, 400), size: Vector2(200, 22), color: Color(0xFFB0BEC5)),
    ArenaPlatformDef(pos: Vector2(180, 280), size: Vector2(140, 22), type: PlatformType.falling, color: Color(0xFFE1F5FE)),
    ArenaPlatformDef(pos: Vector2(500, 280), size: Vector2(140, 22), color: Color(0xFFCFD8DC)),
    ArenaPlatformDef(pos: Vector2(340, 160), size: Vector2(220, 22), type: PlatformType.falling, color: Color(0xFF81D4FA)),
  ],
  spawns: [Vector2(120,140), Vector2(700,140), Vector2(220,310), Vector2(560,310)],
);

final allArenas = [classicArena, volcanoArena, iceArena];

ArenaConfig arenaById(String id) => allArenas.firstWhere((a) => a.id == id, orElse: () => classicArena);
