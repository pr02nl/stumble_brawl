import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_state.dart';
import '../game/ranking.dart';
import '../game/skin_manager.dart';
import '../game/stumble_brawl_game.dart';
import '../clip/clip_exporter.dart';
import 'hud.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  StumbleBrawlGame? game;
  String? lastWinner;
  bool lastWinHuman = false;
  int lastWinnerDamage = 0;

  double touchX = 0;
  bool isTouchLeft = false;
  bool isTouchRight = false;
  final FocusNode _focusNode = FocusNode();
  bool _showKeyboardHelp = kIsWeb;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createGame();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _createGame() {
    final gs = ref.read(gameStateProvider);
    final humanSkins = gs.humanSkins;
    final humanCount = gs.humanCount;
    final arenaId = gs.arenaId;
    // bot skins: pega do pool de skins desbloqueadas aleatórias que não são dos humanos
    final available = allSkins
        .where((s) => !humanSkins.contains(s.id))
        .map((s) => s.id)
        .toList();
    available.shuffle();
    final botCount = 4 - humanCount;
    final botSkins = List<int>.generate(
      botCount,
      (i) => available[i % available.length],
    );

    game = StumbleBrawlGame(
      humanSkins: humanSkins,
      botSkins: botSkins,
      arenaId: arenaId,
      onWinner: (w, isHuman) {
        // pega dano do vencedor para ranking
        final winnerPlayer = game!.players.firstWhere(
          (p) => p.name == w,
          orElse: () => game!.players.first,
        );
        setState(() {
          lastWinner = w;
          lastWinHuman = isHuman;
          lastWinnerDamage = winnerPlayer.damage.toInt();
        });
      },
      onGameOver: () async {
        if (!mounted) return;
        final winner = lastWinner ?? 'Empate';
        // registra ranking e moedas
        final ranking = RankingManager();
        await ranking.load();
        await ranking.recordGame(
          winner: winner,
          winnerDamage: lastWinnerDamage,
          isHumanWin: lastWinHuman,
        );

        if (lastWinHuman) {
          final skinMgr = SkinManager();
          await skinMgr.load();
          await skinMgr.addCoins(20);
        }

        ref
            .read(gameStateProvider.notifier)
            .toGameOver(winner, isHuman: lastWinHuman);
      },
    );
    setState(() {});
  }

  void _updateHumanInput() {
    if (game == null) return;
    double x = 0;
    if (isTouchLeft) x -= 1;
    if (isTouchRight) x += 1;
    if (touchX != 0) x = touchX;
    game!.setHumanInputSingle(x: x);
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameStateProvider);

    if (gs.screen == AppScreen.gameOver) {
      return _buildGameOver(
        gs.winnerName ?? lastWinner ?? 'Empate',
        gs.winnerIsHuman || lastWinHuman,
      );
    }

    if (game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyH) {
            setState(() => _showKeyboardHelp = !_showKeyboardHelp);
            return KeyEventResult.handled;
          }
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            ref.read(gameStateProvider.notifier).toMenu();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            GameWidget(
              game: game!,
              overlayBuilderMap: {
                'hud': (ctx, g) {
                  final gg = g as StumbleBrawlGame;
                  return StreamBuilder(
                    stream: Stream.periodic(const Duration(milliseconds: 100)),
                    builder: (c, _) => Hud(
                      timeLeft: (gg.roundTime - gg.elapsed).clamp(0, 999),
                      elapsed: gg.elapsed,
                      players: gg.players,
                      isSpectating: gg.isSpectating,
                    ),
                  );
                },
              },
              initialActiveOverlays: const ['hud'],
            ),
            if (kIsWeb && _showKeyboardHelp)
              Positioned(
                top: 60,
                left: 12,
                right: 12,
                child: SafeArea(child: _buildKeyboardHelp()),
              ),
            if (!(kIsWeb && MediaQuery.of(context).size.width > 700))
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          _TouchButton(
                            icon: Icons.arrow_left_rounded,
                            onDown: (_) => setState(() {
                              isTouchLeft = true;
                              _updateHumanInput();
                            }),
                            onUp: (_) => setState(() {
                              isTouchLeft = false;
                              _updateHumanInput();
                            }),
                            onCancel: () => setState(() {
                              isTouchLeft = false;
                              _updateHumanInput();
                            }),
                          ),
                          const SizedBox(width: 8),
                          _TouchButton(
                            icon: Icons.arrow_right_rounded,
                            onDown: (_) => setState(() {
                              isTouchRight = true;
                              _updateHumanInput();
                            }),
                            onUp: (_) => setState(() {
                              isTouchRight = false;
                              _updateHumanInput();
                            }),
                            onCancel: () => setState(() {
                              isTouchRight = false;
                              _updateHumanInput();
                            }),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onPanUpdate: (d) {
                          final dx = d.delta.dx;
                          setState(() {
                            touchX = (dx * 0.08).clamp(-1.0, 1.0);
                            if (d.localPosition.dx < 0) touchX = -1;
                            if (d.localPosition.dx > 120) touchX = 1;
                          });
                          _updateHumanInput();
                        },
                        onPanEnd: (_) => setState(() {
                          touchX = 0;
                          _updateHumanInput();
                        }),
                        child: Container(
                          width: 110,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.swipe,
                                color: Colors.white70,
                                size: 18,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'ARRASTE',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _ActionButton(
                            label: 'PULO',
                            color: const Color(0xFF4CD964),
                            icon: Icons.arrow_upward_rounded,
                            onTapDown: (_) {
                              game!.setHumanInputSingle(
                                jump: true,
                                jumpPressed: true,
                              );
                            },
                            onTapUp: (_) {
                              game!.setHumanInputSingle(jump: false);
                            },
                          ),
                          const SizedBox(width: 10),
                          _ActionButton(
                            label: 'SOCO',
                            color: const Color(0xFFFF3B30),
                            icon: Icons.sports_mma,
                            onTapDown: (_) {
                              game!.setHumanInputSingle(
                                punch: true,
                                punchPressed: true,
                              );
                            },
                            onTapUp: (_) {
                              game!.setHumanInputSingle(punch: false);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 44, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            ref.read(gameStateProvider.notifier).toMenu(),
                        icon: const Icon(Icons.close),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.videogame_asset,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${game!.multiGamepad?.connectedCount ?? 0} controle(s)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: _showKeyboardHelp ? 'Esconder teclado (H)' : 'Ver teclado (H)',
                        style: IconButton.styleFrom(
                          backgroundColor: _showKeyboardHelp ? Colors.white : Colors.black54,
                          foregroundColor: _showKeyboardHelp ? Colors.black87 : Colors.white,
                        ),
                        onPressed: () => setState(() => _showKeyboardHelp = !_showKeyboardHelp),
                        icon: Icon(_showKeyboardHelp ? Icons.keyboard_hide : Icons.keyboard),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          game!.restart();
                          setState(() => lastWinner = null);
                          _focusNode.requestFocus();
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardHelp() {
    final isMulti = (game?.humanInputs.length ?? 1) > 1;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.keyboard, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('CONTROLES TECLADO (Web)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                onPressed: () => setState(() => _showKeyboardHelp = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 12),
          if (!isMulti) ...[
            _keyRow('← → ou A D', 'Mover'),
            _keyRow('W ou ↑ ou ESPAÇO', 'Pular (duplo pulo)'),
            _keyRow('F ou J ou X ou ENTER', 'Soco'),
            _keyRow('H', 'Mostrar/esconder ajuda'),
            _keyRow('ESC', 'Menu  •  R reinicia'),
          ] else ...[
            _keyRow('P1: A D | W | F', 'Mover | Pular | Soco'),
            _keyRow('P2: ← → | ↑ | ENTER/K', 'Mover | Pular | Soco'),
            if ((game?.humanInputs.length ?? 0) > 2) _keyRow('P3: J L | I | U', 'Mover | Pular | Soco'),
            if ((game?.humanInputs.length ?? 0) > 3) _keyRow('P4: Numpad 4 6 | 8 | 1', 'Mover | Pular | Soco'),
            _keyRow('H / ESC / R', 'Ajuda / Menu / Reinicia'),
            const SizedBox(height: 4),
            const Text('Dica: No web com 1 jogador, WASD e Setas funcionam juntos. Conecte controles para TV.', style: TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  Widget _keyRow(String keys, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
            child: Text(keys, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 10)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(action, style: const TextStyle(color: Colors.white70, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildGameOver(String winner, bool isHuman) {
    final isYou = winner == 'Você' || winner.startsWith('P') || isHuman;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isYou
                ? [const Color(0xFFFFD60A), const Color(0xFFFF9500)]
                : [const Color(0xFF9D4EDD), const Color(0xFF5A189A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isYou ? '🏆' : '💥', style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 8),
              Text(
                isYou ? 'VITÓRIA!' : 'FIM DE JOGO',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Vencedor: $winner',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isYou) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CD964),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '+20 moedas!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: 250,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 6,
                  ),
                  onPressed: () {
                    ref.read(gameStateProvider.notifier).toPlaying();
                    setState(() {
                      lastWinner = null;
                      _createGame();
                    });
                  },
                  child: const Text(
                    'JOGAR NOVAMENTE',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 250,
                height: 44,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('COMPARTILHAR CLIPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (game != null) await ClipExporter.shareResult(game!, winner);
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 250,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () =>
                      ref.read(gameStateProvider.notifier).toMenu(),
                  child: const Text(
                    'MENU',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TouchButton extends StatelessWidget {
  final IconData icon;
  final Function(TapDownDetails) onDown;
  final Function(TapUpDetails) onUp;
  final VoidCallback onCancel;
  const _TouchButton({
    required this.icon,
    required this.onDown,
    required this.onUp,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onDown,
      onTapUp: onUp,
      onTapCancel: onCancel,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.black12, width: 1.5),
        ),
        child: Icon(icon, size: 36, color: Colors.black87),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final Function(TapDownDetails) onTapDown;
  final Function(TapUpDetails) onTapUp;
  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: () => onTapUp(TapUpDetails(kind: PointerDeviceKind.touch)),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
