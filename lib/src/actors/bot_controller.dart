import 'dart:math';
import '../input/input_state.dart';
import 'player.dart';
import '../world/platform.dart';

class BotController {
  final Player bot;
  final InputState input;
  final List<Platform> platforms;
  final List<Player> allPlayers;
  final Random _rng = Random();
  double _decisionTimer = 0;
  double _targetX = 0;
  Player? _targetEnemy;
  double _stuckTime = 0;
  double _lastX = 0;

  BotController({
    required this.bot,
    required this.input,
    required this.platforms,
    required this.allPlayers,
  });

  void update(double dt) {
    if (!bot.isAlive) {
      input.x = 0;
      input.jump = false;
      input.punch = false;
      return;
    }

    _decisionTimer -= dt;
    if (_decisionTimer <= 0) {
      _decisionTimer = 0.25 + _rng.nextDouble() * 0.35;
      _chooseTarget();
      _chooseMovement();
    }

    // Controle de pulo para buracos
    _handleJump(dt);

    // Soco se perto
    _handlePunch();

    // Anti-stuck: se não se moveu, pula
    if ((bot.position.x - _lastX).abs() < 1) {
      _stuckTime += dt;
      if (_stuckTime > 0.6) {
        input.jumpPressedThisFrame = true;
        input.jump = true;
        _stuckTime = 0;
      }
    } else {
      _stuckTime = 0;
    }
    _lastX = bot.position.x;

    // Limpa flags no próximo frame via game
  }

  void _chooseTarget() {
    Player? closest;
    double best = double.infinity;
    for (final p in allPlayers) {
      if (p.id == bot.id || !p.isAlive) continue;
      final d = (p.position.x - bot.position.x).abs() + (p.position.y - bot.position.y).abs() * 0.5;
      if (d < best) {
        best = d;
        closest = p;
      }
    }
    _targetEnemy = closest;
  }

  void _chooseMovement() {
    if (_targetEnemy == null) {
      // vai para centro
      _targetX = 400 + _rng.nextDouble() * 100 - 50;
    } else {
      _targetX = _targetEnemy!.position.x + _rng.nextDouble() * 40 - 20;
      // às vezes tenta se posicionar para empurrar para borda
      if (_rng.nextDouble() < 0.3) {
        _targetX += _targetEnemy!.facing * 30;
      }
    }
    double diff = _targetX - (bot.position.x + bot.size.x / 2);
    if (diff.abs() < 8) {
      input.x = (_rng.nextDouble() - 0.5) * 0.4;
    } else {
      input.x = diff > 0 ? 1 : -1;
      // variação para não ser perfeito
      if (_rng.nextDouble() < 0.12) input.x *= 0.6;
    }
  }

  void _handleJump(double dt) {
    // Se próximo de borda da plataforma, pula
    if (!bot.isOnGround) return;

    // Detecta se à frente há buraco
    final aheadX = bot.position.x + bot.size.x / 2 + bot.facing * 28;
    final footY = bot.position.y + bot.size.y + 4;
    bool hasGroundAhead = false;
    for (final plat in platforms) {
      if (!plat.isActive) continue;
      if (aheadX >= plat.position.x && aheadX <= plat.position.x + plat.size.x) {
        if ((footY - plat.position.y).abs() < 40 && plat.position.y >= bot.position.y) {
          hasGroundAhead = true;
          break;
        }
      }
    }
    // Se não tem chão e tem alvo além do buraco, pula
    if (!hasGroundAhead) {
      // Tem buraco - decide pular ou parar
      if (_targetEnemy != null) {
        final enemyBeyondHole = (bot.facing == 1 && _targetEnemy!.position.x > bot.position.x) ||
            (bot.facing == -1 && _targetEnemy!.position.x < bot.position.x);
        if (enemyBeyondHole && _rng.nextDouble() < 0.75) {
          input.jumpPressedThisFrame = true;
          input.jump = true;
          // dá um impulso lateral
          input.x = bot.facing.toDouble();
          return;
        } else if (_rng.nextDouble() < 0.4) {
          input.x *= -1; // volta
        }
      }
    } else {
      // Chão normal - pula aleatoriamente para ser imprevisível
      if (_rng.nextDouble() < 0.015) {
        input.jumpPressedThisFrame = true;
        input.jump = true;
      }
    }

    // Se alvo está acima, pula
    if (_targetEnemy != null && _targetEnemy!.position.y < bot.position.y - 30) {
      if (_rng.nextDouble() < 0.06) {
        input.jumpPressedThisFrame = true;
        input.jump = true;
      }
    }
  }

  void _handlePunch() {
    if (_targetEnemy == null || !bot.isAlive) return;
    final dx = (_targetEnemy!.position.x - bot.position.x).abs();
    final dy = (_targetEnemy!.position.y - bot.position.y).abs();
    final facingOk = (_targetEnemy!.position.x > bot.position.x && bot.facing == 1) ||
        (_targetEnemy!.position.x < bot.position.x && bot.facing == -1);
    if (dx < 52 && dy < 36 && facingOk) {
      if (_rng.nextDouble() < 0.5) {
        input.punchPressedThisFrame = true;
        input.punch = true;
      }
    } else {
      input.punch = false;
    }
  }
}
