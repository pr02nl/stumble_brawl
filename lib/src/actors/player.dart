import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../game/stumble_brawl_game.dart';
import '../input/input_state.dart';
import '../world/world_config.dart';

enum PlayerState { idle, run, jump, fall, punch, hit, dead }

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameReference<StumbleBrawlGame>, CollisionCallbacks {
  final int id;
  final String name;
  final Color color;
  final int skinId;
  final bool isHuman;
  final InputState input;

  final Vector2 velocity = Vector2.zero();
  static const double gravity = 1350;
  static const double moveSpeed = 260;
  static const double jumpForce = -560;
  static const double maxFall = 650;
  static const double friction = 0.85;

  bool isOnGround = false;
  bool wasOnGround = false;
  double coyoteTime = 0;
  static const double coyoteDuration = 0.12;
  int jumpsRemaining = 1;

  double punchCooldown = 0;
  static const double punchDuration = 0.18;
  static const double punchCooldownTime = 0.35;
  bool isPunching = false;
  double punchTimer = 0;
  int facing = 1;
  double damage = 0;
  bool isAlive = true;
  double hitStun = 0;
  double invulnTime = 0;

  final Vector2 initialPosition;
  TextComponent? _damageText;
  bool _spriteLoaded = false;

  Player({
    required this.id,
    required this.name,
    required this.color,
    this.skinId = 0,
    required this.isHuman,
    required this.input,
    required Vector2 position,
    required Vector2 size,
  })  : initialPosition = position.clone(),
        super(position: position, size: size, anchor: Anchor.topLeft, current: PlayerState.idle);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(position: Vector2(4, 4), size: Vector2(size.x - 8, size.y - 8)));

    // Damage text as child - positioned above
    _damageText = TextComponent(
      text: '0%',
      anchor: Anchor.center,
      position: Vector2(size.x / 2, -8),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black54, blurRadius: 2)]),
      ),
    );
    add(_damageText!);

    // Try to load spritesheet - fallback to canvas if missing
    try {
      // Ensure image is cached - game preloads it, but load if not
      if (!game.images.containsKey('player_spritesheet.png')) {
        await game.images.load('player_spritesheet.png').timeout(const Duration(seconds: 1));
      }
      final image = game.images.fromCache('player_spritesheet.png');
      final sheet = SpriteSheet(image: image, srcSize: Vector2(36, 44));
      final row = skinId.clamp(0, 11);

      // Helper to get single sprite as animation
      SpriteAnimation single(int col) {
        final sprite = sheet.getSprite(row, col);
        return SpriteAnimation.spriteList([sprite], stepTime: 0.1, loop: true);
      }

      // Run uses 2 frames (idle+run) for subtle movement
      final runSprites = [sheet.getSprite(row, 0), sheet.getSprite(row, 1)];
      final runAnim = SpriteAnimation.spriteList(runSprites, stepTime: 0.12, loop: true);

      animations = {
        PlayerState.idle: single(0),
        PlayerState.run: runAnim,
        PlayerState.jump: single(2),
        PlayerState.fall: single(2),
        PlayerState.punch: single(3),
        PlayerState.hit: single(3),
        PlayerState.dead: single(0),
      };
      current = PlayerState.idle;
      _spriteLoaded = true;

      // Punch should auto-return to idle
      animationTickers?[PlayerState.punch]?.onComplete = () {
        if (current == PlayerState.punch) current = PlayerState.idle;
      };
    } catch (e) {
      // Fallback: keep HasPaint color and will draw canvas in render
      _spriteLoaded = false;
    }
  }

  void reset() {
    position.setFrom(initialPosition);
    velocity.setZero();
    isAlive = true;
    isOnGround = false;
    damage = 0;
    hitStun = 0;
    invulnTime = 1.0;
    isPunching = false;
    punchCooldown = 0;
    opacity = 1;
    if (_spriteLoaded) current = PlayerState.idle;
  }

  void takeHit(Vector2 force, double dmg) {
    if (invulnTime > 0 || !isAlive) return;
    damage += dmg;
    final scale = 1 + damage / 80;
    velocity.setFrom(force * scale);
    velocity.y = (velocity.y - 120).clamp(-800, 800);
    hitStun = 0.18;
    invulnTime = 0.15;
    isOnGround = false;
    if (_spriteLoaded) current = PlayerState.hit;
  }

  bool tryPunch(List<Player> others) {
    if (!isAlive || punchCooldown > 0 || hitStun > 0) return false;
    isPunching = true;
    punchTimer = punchDuration;
    punchCooldown = punchCooldownTime;
    if (_spriteLoaded) current = PlayerState.punch;

    final punchRange = 48.0;
    final punchHeight = size.y * 0.7;
    final punchX = facing == 1 ? position.x + size.x : position.x - punchRange;
    final punchRect = Rect.fromLTWH(punchX, position.y + 8, punchRange, punchHeight);

    bool hitSomeone = false;
    for (final other in others) {
      if (other.id == id || !other.isAlive) continue;
      final otherRect = Rect.fromLTWH(other.position.x, other.position.y, other.size.x, other.size.y);
      if (punchRect.overlaps(otherRect)) {
        final dir = facing.toDouble();
        other.takeHit(Vector2(dir * 520, -180), 12);
        other.velocity.x += dir * 80;
        hitSomeone = true;
      }
    }
    return hitSomeone;
  }

  void _updateAnimation() {
    if (!_spriteLoaded) return;
    if (!isAlive) {
      current = PlayerState.dead;
      return;
    }
    if (hitStun > 0) {
      current = PlayerState.hit;
      return;
    }
    if (isPunching) {
      current = PlayerState.punch;
      return;
    }
    if (!isOnGround) {
      current = velocity.y < 0 ? PlayerState.jump : PlayerState.fall;
      return;
    }
    if (input.x.abs() > 0.15) {
      current = PlayerState.run;
    } else {
      current = PlayerState.idle;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) {
      // still update damage text opacity
      if (invulnTime > 0) setOpacity(((invulnTime * 10) % 2 < 1) ? 0.4 : 1.0);
      _damageText?.text = '${damage.toInt()}%';
      if (invulnTime > 0) invulnTime -= dt;
      return;
    }

    if (hitStun > 0) {
      hitStun -= dt;
      velocity.y += gravity * dt;
      velocity.y = velocity.y.clamp(-maxFall, maxFall);
      position += velocity * dt;
      _clampWorld();
      if (invulnTime > 0) invulnTime -= dt;
      _damageText?.text = '${damage.toInt()}%';
      _updateAnimation();
      if ((facing == 1 && scale.x < 0) || (facing == -1 && scale.x > 0)) {
        flipHorizontallyAroundCenter();
        if (_damageText != null) _damageText!.scale.x = scale.x < 0 ? -1 : 1;
      }
      return;
    }

    if (invulnTime > 0) {
      invulnTime -= dt;
      setOpacity(((invulnTime * 10) % 2 < 1) ? 0.4 : 1.0);
    } else {
      setOpacity(1.0);
    }
    if (punchCooldown > 0) punchCooldown -= dt;
    if (isPunching) {
      punchTimer -= dt;
      if (punchTimer <= 0) isPunching = false;
    }

    double targetX = input.x * moveSpeed;
    velocity.x += (targetX - velocity.x) * 0.22;
    if (targetX == 0) velocity.x *= friction;

    if (input.x.abs() > 0.15) {
      facing = input.x > 0 ? 1 : -1;
    }

    if (!isOnGround) coyoteTime -= dt;
    wasOnGround = isOnGround;
    isOnGround = false;

    if (input.jumpPressedThisFrame) {
      if (isOnGround || coyoteTime > 0) {
        velocity.y = jumpForce;
        isOnGround = false;
        coyoteTime = 0;
        jumpsRemaining = 0;
      } else if (jumpsRemaining > 0) {
        velocity.y = jumpForce * 0.92;
        jumpsRemaining = 0;
      }
    }
    if (!input.jump && velocity.y < -150) {
      velocity.y *= 0.92;
    }

    velocity.y += gravity * dt;
    velocity.y = velocity.y.clamp(-maxFall, maxFall);

    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    _clampWorld();

    if (position.y > WorldConfig.killY) {
      isAlive = false;
      velocity.setZero();
      if (_spriteLoaded) current = PlayerState.dead;
    }

    _damageText?.text = '${damage.toInt()}%';
    _updateAnimation();

    if (_spriteLoaded) {
      final shouldFlip = facing == -1;
      final isFlipped = scale.x < 0;
      if (shouldFlip != isFlipped) {
        flipHorizontallyAroundCenter();
        // counter-flip damageText para não espelhar
        if (_damageText != null) {
          _damageText!.scale.x = scale.x < 0 ? -1 : 1;
        }
      }
    } else {
      // fallback sem sprite também mantém damageText legível
      if (_damageText != null) _damageText!.scale.x = 1;
    }

    if (!isAlive) {
      _damageText?.text = '💀 ${damage.toInt()}%';
    }
  }

  void _clampWorld() {
    if (position.x < -20) position.x = -20;
    if (position.x + size.x > WorldConfig.width) position.x = WorldConfig.width - size.x;
  }

  void landOn(double platformTop) {
    if (velocity.y >= 0) {
      position.y = platformTop - size.y;
      velocity.y = 0;
      isOnGround = true;
      coyoteTime = coyoteDuration;
      jumpsRemaining = 1;
    }
  }

  @override
  void render(Canvas canvas) {
    // Sombra sempre desenhada antes do sprite
    final isInvulnBlink = invulnTime > 0 && (invulnTime * 10) % 2 < 1;
    final alpha = isInvulnBlink ? 0.4 : 1.0;
    canvas.save();
    // Se sprite não carregou, fallback para canvas antigo
    if (!_spriteLoaded) {
      // Sombra
      canvas.drawOval(Rect.fromLTWH(4, size.y - 6, size.x - 8, 6), Paint()..color = Colors.black.withValues(alpha: 0.2 * alpha));
      // Corpo fallback cor
      final bodyRect = RRect.fromRectAndRadius(Rect.fromLTWH(2, 4, size.x - 4, size.y - 8), const Radius.circular(10));
      canvas.drawRRect(bodyRect, Paint()..color = color.withValues(alpha: alpha));
      canvas.drawRRect(bodyRect, Paint()..color = Colors.black.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 2);
      // Olhos fallback
      final eyeY = 12.0;
      final eyeDx = facing == 1 ? 4.0 : -4.0;
      canvas.drawCircle(Offset(size.x / 2 - 6 + eyeDx, eyeY), 3, Paint()..color = Colors.white.withValues(alpha: alpha));
      canvas.drawCircle(Offset(size.x / 2 + 6 + eyeDx, eyeY), 3, Paint()..color = Colors.white.withValues(alpha: alpha));
      canvas.drawCircle(Offset(size.x / 2 - 6 + eyeDx, eyeY), 1.5, Paint()..color = Colors.black.withValues(alpha: alpha));
      canvas.drawCircle(Offset(size.x / 2 + 6 + eyeDx, eyeY), 1.5, Paint()..color = Colors.black.withValues(alpha: alpha));
      if (isPunching) {
        final double punchX = facing == 1 ? size.x - 2 : -16;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(punchX, size.y / 2 - 6, 18, 12), const Radius.circular(4)), Paint()..color = Colors.white.withValues(alpha: alpha));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(punchX, size.y / 2 - 6, 18, 12), const Radius.circular(4)), Paint()..color = Colors.black.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 1.2);
      } else {
        canvas.drawCircle(Offset(facing == 1 ? size.x - 2 : 2, size.y / 2), 5, Paint()..color = Colors.white.withValues(alpha: alpha * 0.9));
      }
      if (!isAlive) {
        final tp = TextPainter(text: const TextSpan(text: '💀', style: TextStyle(fontSize: 16)), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(size.x / 2 - tp.width / 2, size.y / 2 - 10));
      }
      canvas.restore();
      // Não chama super.render pois não temos sprite
      // Mas precisa desenhar damageText via component children - já é child, então super.render desenharia? Evita double
      // For fallback we already handled, so skip super
      // Render children manually (damage text)
      return;
    }

    // Sprite carregado: desenha sombra antes e deixa super desenhar sprite + children
    canvas.drawOval(Rect.fromLTWH(4, size.y - 6, size.x - 8, 6), Paint()..color = Colors.black.withValues(alpha: 0.2));
    canvas.restore();
    super.render(canvas);
  }
}
