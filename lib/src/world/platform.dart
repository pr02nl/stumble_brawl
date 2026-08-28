import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum PlatformType { normal, falling }

class Platform extends PositionComponent with CollisionCallbacks {
  final PlatformType type;
  double _timeOnPlatform = 0;
  bool _triggered = false;
  bool _isFalling = false;
  double _fallSpeed = 0;

  final Color _color;
  Color get color => _color;

  Platform({
    required Vector2 position,
    required Vector2 size,
    this.type = PlatformType.normal,
    this._color = const Color(0xFF8D6E63),
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
    // Visual é desenhado no render, mas adicionamos filho para debug opcional
  }

  void triggerFall() {
    if (type == PlatformType.falling && !_triggered) {
      _triggered = true;
    }
  }

  bool get isActive => !_isFalling || position.y < 2000;

  @override
  void update(double dt) {
    super.update(dt);
    if (_triggered && !_isFalling) {
      _timeOnPlatform += dt;
      // Pisca antes de cair
      if (_timeOnPlatform > 0.8) {
        _isFalling = true;
        _fallSpeed = 0;
      }
    }
    if (_isFalling) {
      _fallSpeed += 900 * dt;
      position.y += _fallSpeed * dt;
      // Remove hitbox quando caindo muito
      if (_fallSpeed > 100 &&
          children.whereType<RectangleHitbox>().isNotEmpty) {
        // mantém hitbox mas deixa cair junto
      }
      if (position.y > 1500) {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = _color;
    if (_triggered && !_isFalling) {
      // pisca vermelho
      final t = (_timeOnPlatform * 10) % 2;
      paint.color = t < 1 ? const Color(0xFFFF6B6B) : _color;
    }
    if (_isFalling) {
      paint.color = _color.withValues(alpha: 0.6);
    }
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, paint);
    // borda
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Detalhe tipo madeira
    canvas.drawRect(
      Rect.fromLTWH(4, size.y / 2 - 1, size.x - 8, 2),
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
  }

  // Reset para reiniciar rodada
  void reset(Vector2 originalPos) {
    position.setFrom(originalPos);
    _triggered = false;
    _isFalling = false;
    _fallSpeed = 0;
    _timeOnPlatform = 0;
  }
}
