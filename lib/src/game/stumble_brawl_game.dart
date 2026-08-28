import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';

import '../actors/bot_controller.dart';
import '../actors/player.dart';
import '../audio/audio_manager.dart';
import '../input/input_state.dart';
import '../input/multi_gamepad.dart';
import '../world/arena.dart';
import '../world/platform.dart';
import '../world/powerup.dart';
import '../world/world_config.dart';
import 'skin_manager.dart';

class StumbleBrawlGame extends FlameGame with HasCollisionDetection {
  final List<int> humanSkins;
  final List<int> botSkins;
  final String arenaId;
  final VoidCallback? onGameOver;
  final void Function(String winner, bool isHuman)? onWinner;

  StumbleBrawlGame({
    required this.humanSkins,
    required this.botSkins,
    this.arenaId = 'classic',
    this.onGameOver,
    this.onWinner,
  }) : humanInputs = List.generate(humanSkins.length, (_) => InputState());

  List<InputState> humanInputs;
  MultiGamepadManager? multiGamepad;
  final List<InputState> botInputs = [];
  final List<Player> players = [];
  final List<Platform> platforms = [];
  final List<BotController> bots = [];
  final List<Vector2> platformOrigins = [];
  final List<PowerUp> powerUps = [];

  double powerUpTimer = 0;
  double nextPowerUpIn = 5;

  bool isGameOver = false;
  double roundTime = 75;
  double elapsed = 0;
  String? winnerName;
  bool winnerIsHuman = false;

  static final Vector2 _playerSize = Vector2(WorldConfig.playerSize.x, WorldConfig.playerSize.y);

  @override
  Color backgroundColor() => arenaById(arenaId).bgColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Preload spritesheet for Player - 12 skins x 4 frames
    try {
      await images
          .load('player_spritesheet.png')
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // fallback if missing - Player will use canvas
    }
    try {
      await audioManager.init().timeout(const Duration(seconds: 1));
      audioManager.playBgm();
    } catch (_) {}

    multiGamepad = MultiGamepadManager(humanInputs);
    try {
      await multiGamepad!.init().timeout(const Duration(seconds: 1));
    } catch (_) {}

    // HardwareKeyboardDetector - bypass Focus, funciona no web sem clique
    add(HardwareKeyboardDetector(onKeyEvent: _handleHardwareKey));

    for (int i = 0; i < botSkins.length; i++) {
      botInputs.add(InputState());
    }

    _buildLevel();
    _spawnPlayers();
  }

  void _buildLevel() {
    for (final p in platforms) {
      p.removeFromParent();
    }
    platforms.clear();
    platformOrigins.clear();
    for (final pu in powerUps) {
      pu.removeFromParent();
    }
    powerUps.clear();
    final arena = arenaById(arenaId);
    for (final def in arena.platforms) {
      _addPlat(def.pos.clone(), def.size.clone(), type: def.type, color: def.color);
    }
  }

  void _addPlat(
    Vector2 pos,
    Vector2 size, {
    PlatformType type = PlatformType.normal,
    required Color color,
  }) {
    final p = Platform(position: pos, size: size, type: type, color: color);
    platforms.add(p);
    platformOrigins.add(pos.clone());
    world.add(p);
  }

  void _spawnPlayers() {
    for (final p in players) {
      p.removeFromParent();
    }
    players.clear();
    bots.clear();
    botInputs.clear();
    for (int i = 0; i < botSkins.length; i++) {
      botInputs.add(InputState());
    }

    final spawns = arenaById(arenaId).spawns;

    int idx = 0;
    for (int h = 0; h < humanSkins.length; h++) {
      final skin = allSkins.firstWhere(
        (s) => s.id == humanSkins[h],
        orElse: () => allSkins[0],
      );
      final name = h == 0 ? 'Você' : 'P${h + 1}';
      final player = Player(
        id: idx,
        name: name,
        color: skin.color,
        skinId: skin.id,
        isHuman: true,
        input: humanInputs[h],
        position:
            spawns[idx % 4].clone() +
            Vector2(Random().nextDouble() * 20 - 10, 0),
        size: _playerSize.clone(),
      );
      players.add(player);
      world.add(player);
      idx++;
    }
    // Bots
    for (int b = 0; b < botSkins.length; b++) {
      final skin = allSkins.firstWhere(
        (s) => s.id == botSkins[b],
        orElse: () => allSkins[0],
      );
      final player = Player(
        id: idx,
        name: 'Bot ${b + 1}',
        color: skin.color,
        skinId: skin.id,
        isHuman: false,
        input: botInputs[b],
        position:
            spawns[idx % 4].clone() +
            Vector2(Random().nextDouble() * 20 - 10, 0),
        size: _playerSize.clone(),
      );
      players.add(player);
      world.add(player);
      idx++;
    }

    for (int b = 0; b < botInputs.length; b++) {
      final botPlayer = players[humanSkins.length + b];
      bots.add(
        BotController(
          bot: botPlayer,
          input: botInputs[b],
          platforms: platforms,
          allPlayers: players,
        ),
      );
    }

    elapsed = 0;
    isGameOver = false;
    winnerName = null;
    winnerIsHuman = false;
    powerUpTimer = 0;
    nextPowerUpIn = 4 + Random().nextDouble() * 3;
    _lastTouch.clear();
    for (int i = 0; i < humanSkins.length; i++) {
      _lastTouch.add(null);
    }
  }

  void restart() {
    for (int i = 0; i < platforms.length; i++) {
      platforms[i].reset(platformOrigins[i]);
      if (!platforms[i].isMounted) world.add(platforms[i]);
    }
    for (final pu in List<PowerUp>.from(powerUps)) {
      pu.removeFromParent();
    }
    powerUps.clear();
    for (final p in players) {
      p.reset();
    }
    final spawns = arenaById(arenaId).spawns;
    for (int i = 0; i < players.length; i++) {
      final base = spawns[i % spawns.length].clone() + Vector2(Random().nextDouble()*20-10,0);
      players[i].position.setFrom(base);
      players[i].initialPosition.setFrom(base);
    }
    elapsed = 0;
    isGameOver = false;
    winnerName = null;
    winnerIsHuman = false;
    powerUpTimer = 0;
    nextPowerUpIn = 4 + Random().nextDouble() * 3;
  }

  final List<DateTime?> _lastTouch = [];

  void notifyTouch(int idx) {
    while (_lastTouch.length <= idx) {
      _lastTouch.add(null);
    }
    _lastTouch[idx] = DateTime.now();
  }

  bool _touchRecent(int idx) {
    if (idx >= _lastTouch.length || _lastTouch[idx]==null) return false;
    return DateTime.now().difference(_lastTouch[idx]!).inMilliseconds < 300;
  }

  void setHumanInput(
    int playerIndex, {
    double? x,
    bool? jump,
    bool? punch,
    bool jumpPressed = false,
    bool punchPressed = false,
  }) {
    if (x != null) notifyTouch(playerIndex);
    multiGamepad?.handleKeyboardPlayer(
      playerIndex,
      x: x,
      jump: jump,
      punch: punch,
      jumpPressed: jumpPressed,
      punchPressed: punchPressed,
    );
  }

  // Compatibilidade single player
  void setHumanInputSingle({
    double? x,
    bool? jump,
    bool? punch,
    bool jumpPressed = false,
    bool punchPressed = false,
  }) {
    setHumanInput(
      0,
      x: x,
      jump: jump,
      punch: punch,
      jumpPressed: jumpPressed,
      punchPressed: punchPressed,
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewport.size = size;
    final scale = min(size.x / WorldConfig.width, size.y / WorldConfig.height);
    camera.viewfinder.zoom = scale;
    final offsetX = (size.x - WorldConfig.width * scale) / 2 / scale;
    final offsetY = (size.y - WorldConfig.height * scale) / 2 / scale;
    camera.viewfinder.position = Vector2(-offsetX, -offsetY);
  }

  void _handleHardwareKey(KeyEvent event) {
    final keysPressed = HardwareKeyboard.instance.logicalKeysPressed;
    final isDown = event is KeyDownEvent;

    // Web facilitado: suporte a 1-4 jogadores no teclado - bypass Focus via HardwareKeyboardDetector
    for (int i = 0; i < humanInputs.length; i++) {
      double x = 0;
      bool jump = false;
      bool punch = false;

      if (humanInputs.length == 1) {
        if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
            keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
          x -= 1;
        }
        if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
            keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
          x += 1;
        }
        jump =
            keysPressed.contains(LogicalKeyboardKey.keyW) ||
            keysPressed.contains(LogicalKeyboardKey.space) ||
            keysPressed.contains(LogicalKeyboardKey.arrowUp);
        punch =
            keysPressed.contains(LogicalKeyboardKey.keyF) ||
            keysPressed.contains(LogicalKeyboardKey.keyJ) ||
            keysPressed.contains(LogicalKeyboardKey.keyX) ||
            keysPressed.contains(LogicalKeyboardKey.enter) ||
            keysPressed.contains(LogicalKeyboardKey.keyK) ||
            keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
            keysPressed.contains(LogicalKeyboardKey.controlLeft);
      } else {
        if (i == 0) {
          if (keysPressed.contains(LogicalKeyboardKey.keyA)) x -= 1;
          if (keysPressed.contains(LogicalKeyboardKey.keyD)) x += 1;
          jump =
              keysPressed.contains(LogicalKeyboardKey.keyW) ||
              keysPressed.contains(LogicalKeyboardKey.space);
          punch =
              keysPressed.contains(LogicalKeyboardKey.keyF) ||
              keysPressed.contains(LogicalKeyboardKey.keyG);
        } else if (i == 1) {
          if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) x -= 1;
          if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) x += 1;
          jump =
              keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
              keysPressed.contains(LogicalKeyboardKey.numpad0);
          punch =
              keysPressed.contains(LogicalKeyboardKey.enter) ||
              keysPressed.contains(LogicalKeyboardKey.numpad1) ||
              keysPressed.contains(LogicalKeyboardKey.keyK);
        } else if (i == 2) {
          if (keysPressed.contains(LogicalKeyboardKey.keyJ)) x -= 1;
          if (keysPressed.contains(LogicalKeyboardKey.keyL)) x += 1;
          jump =
              keysPressed.contains(LogicalKeyboardKey.keyI) ||
              keysPressed.contains(LogicalKeyboardKey.keyO);
          punch =
              keysPressed.contains(LogicalKeyboardKey.keyU) ||
              keysPressed.contains(LogicalKeyboardKey.keyP);
        } else if (i == 3) {
          if (keysPressed.contains(LogicalKeyboardKey.numpad4)) x -= 1;
          if (keysPressed.contains(LogicalKeyboardKey.numpad6)) x += 1;
          jump =
              keysPressed.contains(LogicalKeyboardKey.numpad8) ||
              keysPressed.contains(LogicalKeyboardKey.numpad5);
          punch =
              keysPressed.contains(LogicalKeyboardKey.numpad1) ||
              keysPressed.contains(LogicalKeyboardKey.numpadEnter);
        }
      }

      // não sobrescreve touch recente com x=0 do teclado
      final touchRecent = _touchRecent(i);
      final effectiveX = (touchRecent && x==0) ? null : x;
      multiGamepad?.handleKeyboardPlayer(
        i,
        x: effectiveX,
        jump: jump,
        punch: punch,
        jumpPressed: isDown && jump,
        punchPressed: isDown && punch,
      );
    }

    if (isDown && keysPressed.contains(LogicalKeyboardKey.keyR) && isGameOver) {
      restart();
    }
  }

  void _spawnPowerUp() {
    if (powerUps.length >= 3) return;
    final plat = platforms[Random().nextInt(platforms.length)];
    final x =
        plat.position.x +
        plat.size.x / 2 -
        14 +
        Random().nextDouble() * 20 -
        10;
    final y = plat.position.y - 36;
    final type =
        PowerUpType.values[Random().nextInt(PowerUpType.values.length)];
    final pu = PowerUp(type: type, position: Vector2(x, y));
    powerUps.add(pu);
    world.add(pu);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;
    elapsed += dt;
    powerUpTimer += dt;
    if (powerUpTimer >= nextPowerUpIn) {
      powerUpTimer = 0;
      nextPowerUpIn = 4 + Random().nextDouble() * 4;
      _spawnPowerUp();
    }

    for (final bot in bots) {
      bot.update(dt);
    }

    // Detecta pulo para audio
    for (int i = 0; i < humanInputs.length; i++) {
      if (humanInputs[i].jumpPressedThisFrame) audioManager.playJump();
      if (humanInputs[i].punchPressedThisFrame) {
        final p = players[i];
        if (p.isAlive) {
          audioManager.playPunch();
          if (p.tryPunch(players)) audioManager.playHit();
        }
      }
    }
    for (int i = 0; i < botInputs.length; i++) {
      if (botInputs[i].punchPressedThisFrame) {
        final p = players[humanInputs.length + i];
        if (p.tryPunch(players)) audioManager.playHit();
      }
      // bot pulo audio opcional
    }

    // Colisão powerup
    for (final pu in List<PowerUp>.from(powerUps)) {
      for (final p in players) {
        if (!p.isAlive) continue;
        final pr = Rect.fromLTWH(
          p.position.x,
          p.position.y,
          p.size.x,
          p.size.y,
        );
        final ur = Rect.fromLTWH(
          pu.position.x,
          pu.position.y,
          pu.size.x,
          pu.size.y,
        );
        if (pr.overlaps(ur)) {
          pu.apply(p);
          audioManager.playPowerUp();
          powerUps.remove(pu);
          break;
        }
      }
    }

    // Colisão plataforma
    for (final player in players) {
      if (!player.isAlive) continue;
      final wasY = player.position.y;
      for (final plat in platforms) {
        if (!plat.isActive) continue;
        final px = player.position.x,
            py = player.position.y,
            pw = player.size.x,
            ph = player.size.y;
        final rx = plat.position.x,
            ry = plat.position.y,
            rw = plat.size.x,
            rh = plat.size.y;
        final overlaps =
            px < rx + rw && px + pw > rx && py < ry + rh && py + ph > ry;
        if (!overlaps) continue;
        final prevBottom = wasY + ph - player.velocity.y * dt;
        final currBottom = py + ph;
        if (player.velocity.y >= 0 &&
            prevBottom <= ry + 4 &&
            currBottom >= ry) {
          player.landOn(ry);
          if (plat.type == PlatformType.falling) plat.triggerFall();
        } else if (player.velocity.y < 0 && py < ry + rh && py > ry) {
          player.position.y = ry + rh;
          player.velocity.y = 0;
        } else {
          if (player.velocity.x > 0 && px + pw > rx && px < rx) {
            player.position.x = rx - pw;
            player.velocity.x = 0;
          } else if (player.velocity.x < 0 &&
              px < rx + rw &&
              px + pw > rx + rw) {
            player.position.x = rx + rw;
            player.velocity.x = 0;
          }
        }
      }
      if (player.position.y > WorldConfig.killY && player.isAlive) {
        player.isAlive = false;
        audioManager.playFall();
      }
    }

    final alive = players.where((p) => p.isAlive).toList();
    if (alive.length <= 1 || elapsed >= roundTime) {
      if (!isGameOver) {
        isGameOver = true;
        if (alive.length == 1) {
          winnerName = alive.first.name;
          winnerIsHuman = alive.first.isHuman;
        } else if (alive.isEmpty) {
          winnerName = 'Empate';
          winnerIsHuman = false;
        } else {
          alive.sort((a, b) => a.damage.compareTo(b.damage));
          winnerName = alive.first.name;
          winnerIsHuman = alive.first.isHuman;
        }
        if (winnerIsHuman) {
          audioManager.playWin();
        } else {
          audioManager.playFall();
        }
        onWinner?.call(winnerName!, winnerIsHuman);
        Future.delayed(const Duration(milliseconds: 900), () {
          onGameOver?.call();
        });
      }
    }

    multiGamepad?.clearFrame();
    for (final bi in botInputs) {
      bi.clearFrameFlags();
    }
  }

  @override
  void onRemove() {
    multiGamepad?.dispose();
    audioManager.stopBgm();
    super.onRemove();
  }
}
