import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:stumble_brawl/src/world/powerup.dart';
import 'package:stumble_brawl/src/actors/player.dart';
import 'package:stumble_brawl/src/input/input_state.dart';
import 'package:flutter/material.dart';

Player makePlayer() => Player(
      id: 0,
      name: 'Você',
      color: Colors.red,
      skinId: 0,
      isHuman: true,
      input: InputState(),
      position: Vector2(100, 100),
      size: Vector2(36, 44),
    );

void main() {
  group('PowerUp', () {
    test('creation', () {
      final pu = PowerUp(type: PowerUpType.shield, position: Vector2(50, 50));
      expect(pu.type, PowerUpType.shield);
      expect(pu.lifeTime, 12.0);
      expect(pu.collected, false);
    });

    test('lifeTime expires', () {
      final pu = PowerUp(type: PowerUpType.banana, position: Vector2(0, 0));
      pu.update(13);
      expect(pu.isMounted, false); // removed after lifeTime
    });

    test('apply spring', () {
      final p = makePlayer();
      p.velocity.setFrom(Vector2(0, 0));
      final pu = PowerUp(type: PowerUpType.spring, position: Vector2(100, 100));
      pu.apply(p);
      expect(p.velocity.y, -780);
      expect(pu.collected, true);
    });

    test('apply banana reduces damage', () {
      final p = makePlayer()..damage = 50;
      final pu = PowerUp(type: PowerUpType.banana, position: Vector2(0, 0));
      pu.apply(p);
      expect(p.damage, 25);
    });

    test('apply banana clamp 0', () {
      final p = makePlayer()..damage = 10;
      final pu = PowerUp(type: PowerUpType.banana, position: Vector2(0, 0));
      pu.apply(p);
      expect(p.damage, 0);
    });

    test('apply shield', () {
      final p = makePlayer()..damage = 30;
      final pu = PowerUp(type: PowerUpType.shield, position: Vector2(0, 0));
      pu.apply(p);
      expect(p.invulnTime, 3.0);
      expect(p.damage, 20);
    });

    test('apply turbo adds effect', () {
      final p = makePlayer();
      final before = p.children.length;
      final pu = PowerUp(type: PowerUpType.turbo, position: Vector2(0, 0));
      pu.apply(p);
      // TurboEffect is added as child
      expect(p.children.length, greaterThan(before));
      expect(p.children.whereType<TurboEffect>().length, 1);
    });

    test('apply twice ignored', () {
      final p = makePlayer();
      final pu = PowerUp(type: PowerUpType.shield, position: Vector2(0, 0));
      pu.apply(p);
      final inv = p.invulnTime;
      pu.apply(p); // second call should be ignored because collected true
      expect(p.invulnTime, inv);
    });

    test('opacity blink when low life', () {
      final pu = PowerUp(type: PowerUpType.turbo, position: Vector2(0, 0));
      pu.lifeTime = 2.0;
      pu.update(0.1);
      // opacity should toggle
      expect(pu.opacity, isIn([0.4, 1.0]));
    });
  });

  group('TurboEffect', () {
    test('duration expires', () {
      final p = makePlayer();
      final turbo = TurboEffect(duration: 0.5);
      p.add(turbo);
      // need to pump update
      turbo.onMount();
      turbo.update(0.6);
      expect(turbo.isMounted, false);
    });
  });
}
