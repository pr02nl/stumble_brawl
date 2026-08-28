import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../actors/player.dart';

enum PowerUpType { spring, banana, shield, turbo }

class PowerUp extends PositionComponent with CollisionCallbacks, HasGameReference {
  final PowerUpType type;
  double lifeTime = 12.0; // some após 12s
  double bob = 0;
  bool collected = false;

  PowerUp({required this.type, required Vector2 position}) : super(position: position, size: Vector2(28, 28));

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);
    bob += dt * 4;
    position.y += (dt * 10 * (bob % 2 == 0 ? 1 : -1)) * 0.15; // bob leve
    // workaround simples bob senoidal
    lifeTime -= dt;
    if (lifeTime <= 0 && !collected) {
      removeFromParent();
    }
    // pisca nos últimos 3s
    if (lifeTime < 3) {
      opacity = (lifeTime * 5) % 1 < 0.5 ? 0.4 : 1.0;
    }
  }

  // Aplica efeito no player
  void apply(Player p) {
    if (collected) return;
    collected = true;
    switch (type) {
      case PowerUpType.spring:
        p.velocity.y = -780; // super pulo
        p.invulnTime = 0.2;
        break;
      case PowerUpType.banana:
        // quem pega fica com turbo temporário, mas quem pisar escorrega
        // efeito positivo imediato: dano limpo
        p.damage = (p.damage - 25).clamp(0, 999);
        p.velocity.x += p.facing * 120;
        break;
      case PowerUpType.shield:
        p.invulnTime = 3.0;
        p.damage = (p.damage - 10).clamp(0, 999);
        break;
      case PowerUpType.turbo:
        // velocidade 1.6x por 4s
        p.add(TurboEffect(duration: 4.0));
        break;
    }
    removeFromParent();
  }

  double opacity = 1.0;

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    Color col;
    String emoji;
    switch (type) {
      case PowerUpType.spring:
        col = const Color(0xFF4CD964);
        emoji = '🌀';
        break;
      case PowerUpType.banana:
        col = const Color(0xFFFFCC00);
        emoji = '🍌';
        break;
      case PowerUpType.shield:
        col = const Color(0xFF00D1FF);
        emoji = '🛡️';
        break;
      case PowerUpType.turbo:
        col = const Color(0xFFFF3B30);
        emoji = '🚀';
        break;
    }
    // sombra
    canvas.drawCircle(center, 16, Paint()..color = col.withValues(alpha: 0.25 * opacity));
    canvas.drawCircle(center, 14, Paint()..color = col.withValues(alpha: opacity));
    canvas.drawCircle(center, 14, Paint()..color = Colors.white.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 2);
    // emoji
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: 16, shadows: [Shadow(color: Colors.black38, blurRadius: 4)])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }
}

class TurboEffect extends Component with HasGameReference {
  final double duration;
  double _t = 0;
  Player? _player;

  TurboEffect({required this.duration});

  @override
  void onMount() {
    super.onMount();
    final p = parent;
    if (p is Player) {
      _player = p;
      _player!.add(_TurboVisual());
    }
  }

  @override
  void update(double dt) {
    final player = _player;
    if (player == null) {
      // tenta resolver parent se onMount ainda não foi chamado (testes)
      final p = parent;
      if (p is Player) _player = p;
      if (_player == null) return;
    }
    _t += dt;
    // boost contínuo
    _player!.velocity.x *= 1.02;
    if (_t >= duration) {
      removeFromParent();
    }
  }
}

class _TurboVisual extends PositionComponent {
  double _t = 0;
  _TurboVisual() : super(size: Vector2(36, 44));

  @override
  void render(Canvas canvas) {
    _t += 0.1;
    final alpha = (0.5 + 0.5 * (_t % 1)).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-3, 6, 42, 32), const Radius.circular(10)),
      Paint()..color = Colors.white.withValues(alpha: 0.18 * alpha)..style = PaintingStyle.stroke..strokeWidth = 2,
    );
  }
}
