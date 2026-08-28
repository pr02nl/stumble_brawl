import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:stumble_brawl/src/actors/player.dart';
import 'package:stumble_brawl/src/input/input_state.dart';

Player makePlayer({int id = 0, String name = 'Você', bool isHuman = true, InputState? input, Vector2? pos, int skinId = 0}) {
  return Player(
    id: id,
    name: name,
    color: const Color(0xFF00D1FF),
    skinId: skinId,
    isHuman: isHuman,
    input: input ?? InputState(),
    position: pos ?? Vector2(100, 100),
    size: Vector2(36, 44),
  );
}

void main() {
  group('Player logic', () {
    test('initial values', () {
      final p = makePlayer();
      expect(p.isAlive, true);
      expect(p.damage, 0);
      expect(p.isOnGround, false);
      expect(p.facing, 1);
      expect(p.velocity, Vector2.zero());
    });

    test('takeHit applies knockback scaling', () {
      final p = makePlayer();
      p.takeHit(Vector2(100, 0), 10);
      expect(p.damage, 10);
      expect(p.velocity.x, greaterThan(100)); // scaled
      expect(p.hitStun, 0.18);
    });

    test('takeHit blocked by invuln', () {
      final p = makePlayer();
      p.invulnTime = 0.5;
      p.takeHit(Vector2(100, 0), 10);
      expect(p.damage, 0);
    });

    test('takeHit when dead ignored', () {
      final p = makePlayer();
      p.isAlive = false;
      p.takeHit(Vector2(100, 0), 10);
      expect(p.damage, 0);
    });

    test('damage scale increases knockback', () {
      final p1 = makePlayer();
      final p2 = makePlayer()..damage = 80;
      p1.takeHit(Vector2(200, 0), 0);
      final v1 = p1.velocity.x;
      p2.takeHit(Vector2(200, 0), 0);
      final v2 = p2.velocity.x;
      expect(v2, greaterThan(v1));
    });

    test('tryPunch hits other within range', () {
      final input = InputState();
      final p = makePlayer(id: 0, input: input);
      final other = makePlayer(id: 1, pos: Vector2(130, 100));
      p.facing = 1;
      p.position = Vector2(100, 100);
      other.position = Vector2(130, 100);
      final hit = p.tryPunch([p, other]);
      expect(hit, true);
      expect(other.damage, 12);
    });

    test('tryPunch miss out of range', () {
      final p = makePlayer(id: 0);
      final far = makePlayer(id: 1, pos: Vector2(300, 100));
      p.facing = 1;
      final hit = p.tryPunch([p, far]);
      expect(hit, false);
    });

    test('tryPunch cooldown blocks', () {
      final p = makePlayer(id: 0);
      final other = makePlayer(id: 1, pos: Vector2(130, 100));
      p.facing = 1;
      p.tryPunch([p, other]);
      final hit2 = p.tryPunch([p, other]);
      expect(hit2, false);
      expect(p.punchCooldown, greaterThan(0));
    });

    test('tryPunch when dead fails', () {
      final p = makePlayer(id: 0)..isAlive = false;
      final other = makePlayer(id: 1);
      expect(p.tryPunch([p, other]), false);
    });

    test('reset restores', () {
      final p = makePlayer(pos: Vector2(50, 50));
      p.damage = 80;
      p.isAlive = false;
      p.velocity.setFrom(Vector2(100, 100));
      p.reset();
      expect(p.isAlive, true);
      expect(p.damage, 0);
      expect(p.velocity, Vector2.zero());
      expect(p.position, Vector2(50, 50));
    });

    test('landOn sets onGround', () {
      final p = makePlayer();
      p.velocity.setFrom(Vector2(0, 100));
      p.landOn(200);
      expect(p.isOnGround, true);
      expect(p.position.y, 200 - 44);
      expect(p.velocity.y, 0);
    });

    test('landOn ignores when moving up', () {
      final p = makePlayer();
      p.velocity.setFrom(Vector2(0, -100));
      p.position = Vector2(100, 180);
      p.landOn(200);
      // should not land because velocity.y <0 check in landOn? Actually landOn checks velocity.y >=0, but we set velocity -100, so it will not land? But our landOn implementation checks velocity.y >=0 before setting? It does if (velocity.y >=0) { set } . So with -100 it won't.
      // So isOnGround should stay false
      expect(p.isOnGround, false);
    });

    test('update gravity and clamp', () {
      final input = InputState()..x = 1;
      final p = makePlayer(input: input);
      p.position = Vector2(100, 100);
      p.update(0.016);
      expect(p.position.x, greaterThan(100));
      expect(p.velocity.y, greaterThan(0));
    });

    test('update hitStun blocks input', () {
      final input = InputState()..x = 1;
      final p = makePlayer(input: input);
      p.hitStun = 0.1;
      p.invulnTime = 0.1;
      final beforeX = p.position.x;
      p.update(0.016);
      // during hitStun, input ignored - x should not change from input
      expect(p.position.x, equals(beforeX));
      // Ensure hitStun decrements
      expect(p.hitStun, lessThan(0.1));
    });

    test('update facing', () {
      final input = InputState()..x = -1;
      final p = makePlayer(input: input);
      p.update(0.016);
      expect(p.facing, -1);
      input.x = 1;
      p.update(0.016);
      expect(p.facing, 1);
    });

    test('update jump with coyote', () {
      final input = InputState()..jumpPressedThisFrame = true..jump = true;
      final p = makePlayer(input: input);
      p.isOnGround = true;
      p.coyoteTime = 0.1;
      p.update(0.016);
      expect(p.velocity.y, lessThan(0)); // jumped
    });

    test('update death by fall', () {
      final p = makePlayer(pos: Vector2(100, 860));
      p.update(0.016);
      expect(p.isAlive, false);
    });

    test('clamp world bounds', () {
      final p = makePlayer(pos: Vector2(-50, 100));
      p.update(0.016);
      expect(p.position.x, -20);
      final p2 = makePlayer(pos: Vector2(900, 100));
      p2.update(0.016);
      expect(p2.position.x, lessThanOrEqualTo(900 - 36));
    });
  });
}
