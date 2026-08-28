import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:stumble_brawl/src/world/platform.dart';

void main() {
  group('Platform', () {
    test('normal platform not falling', () {
      final p = Platform(position: Vector2(0, 0), size: Vector2(100, 20));
      expect(p.type, PlatformType.normal);
      expect(p.isActive, true);
      p.triggerFall();
      // normal should not trigger
      expect(p.isActive, true);
    });

    test('falling platform triggers and falls', () {
      final p = Platform(position: Vector2(0, 100), size: Vector2(100, 20), type: PlatformType.falling);
      expect(p.isActive, true);
      p.triggerFall();
      // after 0.5s still not falling
      p.update(0.5);
      expect(p.isActive, true);
      expect(p.position.y, 100);
      // after 0.9s total >0.8 triggers fall and moves 144 in same frame (0.4 dt)
      p.update(0.4);
      expect(p.position.y, greaterThan(100));
      expect(p.position.y, closeTo(244, 1));
      p.update(0.1);
      expect(p.position.y, greaterThan(244));
    });

    test('falling platform removed when out of bounds', () {
      final p = Platform(position: Vector2(0, 100), size: Vector2(100, 20), type: PlatformType.falling);
      p.triggerFall();
      p.update(1.0); // trigger
      // simulate many frames to fall below 1500
      for (int i = 0; i < 200; i++) {
        p.update(0.1);
      }
      expect(p.isMounted, false); // removed
    });

    test('reset restores', () {
      final p = Platform(position: Vector2(10, 10), size: Vector2(50, 10), type: PlatformType.falling);
      p.triggerFall();
      p.update(1.5);
      expect(p.position.y, greaterThan(10));
      p.reset(Vector2(10, 10));
      expect(p.position, Vector2(10, 10));
      expect(p.isActive, true);
    });

    test('isActive false when far', () {
      final p = Platform(position: Vector2(0, 2000), size: Vector2(100, 20), type: PlatformType.falling);
      // trigger fall then move
      p.triggerFall();
      p.update(1.0);
      p.position.y = 2000;
      p.update(0.1);
      expect(p.isActive, false);
    });
  });
}
