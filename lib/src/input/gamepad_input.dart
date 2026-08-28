import 'dart:async';
import 'package:gamepads/gamepads.dart';
import 'input_state.dart';

/// Gerencia input de gamepads (TV/controle)
/// Usa package:gamepads ^0.1.11 - stream GamepadEvent
class GamepadInput {
  final InputState state = InputState();
  StreamSubscription<GamepadEvent>? _sub;
  final Set<String> _pressedKeys = {};

  // Deadzone para analógico
  static const double deadZone = 0.25;

  // Mapeamento de teclas comuns
  static const _jumpKeys = {'a', 'cross', 'button_a', '0', 'button 0', 'south'};
  static const _punchKeys = {'x', 'square', 'button_x', '2', 'button 2', 'west'};

  bool get isConnected => _sub != null;

  Future<void> init() async {
    // Verifica gamepads conectados
    try {
      final pads = await Gamepads.list();
      // ignore: avoid_print
      print('Gamepads encontrados: $pads');
    } catch (e) {
      // Web pode falhar
    }

    _sub = Gamepads.events.listen(_onEvent, onError: (e) {
      // ignore: avoid_print
      print('Gamepad error: $e');
    });
  }

  void _onEvent(GamepadEvent event) {
    final key = event.key.toLowerCase();
    final value = event.value;
    final isButton = event.type == KeyType.button;

    // Debug
    // print('Gamepad: $key $value $isButton ${event.gamepadId}');

    if (isButton) {
      final pressed = value > 0.5;
      if (pressed && !_pressedKeys.contains(key)) {
        _pressedKeys.add(key);
        if (_jumpKeys.contains(key) || key.contains('a') && key.length <= 2) {
          state.jump = true;
          state.jumpPressedThisFrame = true;
        }
        if (_punchKeys.contains(key) || key.contains('x') && key.length <= 2) {
          state.punch = true;
          state.punchPressedThisFrame = true;
        }
        // Fallback: mapeia por índice se nome não bater
        if (key == '0' || key == 'button 0') {
          state.jump = true;
          state.jumpPressedThisFrame = true;
        }
        if (key == '2' || key == 'button 2') {
          state.punch = true;
          state.punchPressedThisFrame = true;
        }
      } else if (!pressed) {
        _pressedKeys.remove(key);
        if (_jumpKeys.contains(key) || key == '0' || key == 'button 0') {
          state.jump = false;
        }
        if (_punchKeys.contains(key) || key == '2' || key == 'button 2') {
          state.punch = false;
        }
        // Fallback genérico
        if (key.contains('a') && !_jumpKeys.contains(key)) {
          // pode ser eixo
        }
      }
    } else {
      // Eixo analógico
      if (key.contains('x') ||
          key.contains('left_x') ||
          key.contains('lsx') ||
          key.contains('axis 0') ||
          key == '0' && event.type == KeyType.analog) {
        double v = value;
        if (v.abs() < deadZone) v = 0;
        // Normaliza - alguns controles dão 0..1, outros -1..1
        if (v > 1) v = 1;
        if (v < -1) v = -1;
        state.x = v.clamp(-1.0, 1.0);
      }
      // D-pad (hat)
      if (key.contains('hat') || key.contains('dpad')) {
        state.x = value.clamp(-1.0, 1.0);
        if (state.x.abs() < 0.1) state.x = 0;
      }
    }

    // Suporte extra: teclado mapeado como gamepad em alguns Android TV
    // Teclas de seta esquerda/direita viram eixo X
    if (key == 'dpad_left') state.x = value > 0.5 ? -1 : 0;
    if (key == 'dpad_right') state.x = value > 0.5 ? 1 : 0;
  }

  // Método para injetar input via teclado (para teste em desktop)
  void handleKeyboard({double? x, bool? jump, bool? punch}) {
    if (x != null) state.x = x;
    if (jump != null) {
      if (jump && !state.jump) state.jumpPressedThisFrame = true;
      state.jump = jump;
    }
    if (punch != null) {
      if (punch && !state.punch) state.punchPressedThisFrame = true;
      state.punch = punch;
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  void clearFrame() => state.clearFrameFlags();
}
