import 'dart:async';
import 'package:gamepads/gamepads.dart';
import 'input_state.dart';

/// Gerencia multi-controles: cada gamepadId -> InputState
class MultiGamepadManager {
  final Map<String, InputState> inputsByPadId = {};
  final Map<String, Set<String>> pressedByPad = {};
  final List<InputState> _playerInputs; // referência para players humanos
  final void Function()? onPadConnected;

  StreamSubscription<GamepadEvent>? _sub;
  static const double deadZone = 0.25;

  MultiGamepadManager(this._playerInputs, {this.onPadConnected});

  int get connectedCount => inputsByPadId.length;

  Future<void> init() async {
    try {
      final pads = await Gamepads.list().timeout(const Duration(seconds: 1));
      // ignore: avoid_print
      print('Gamepads detectados: $pads');
    } catch (_) {}
    try {
      _sub = Gamepads.events.listen(_onEvent, onError: (_) {});
    } catch (_) {}
  }

  // Mapeia gamepadId -> playerIndex (0..n-1)
  int _padIndex(String padId) {
    final ids = inputsByPadId.keys.toList();
    return ids.indexOf(padId);
  }

  void _ensurePad(String padId) {
    if (!inputsByPadId.containsKey(padId)) {
      inputsByPadId[padId] = InputState();
      pressedByPad[padId] = {};
      onPadConnected?.call();
      // ignore: avoid_print
      print('Novo gamepad conectado: $padId total=${inputsByPadId.length}');
    }
  }

  void _onEvent(GamepadEvent event) {
    final padId = event.gamepadId;
    _ensurePad(padId);
    final state = inputsByPadId[padId]!;
    final pressed = pressedByPad[padId]!;
    final key = event.key.toLowerCase();
    final value = event.value;
    final isButton = event.type == KeyType.button;

    if (isButton) {
      final isPressed = value > 0.5;
      if (isPressed && !pressed.contains(key)) {
        pressed.add(key);
        // Mapeamento flexível: 0/a/south = pulo, 2/x/west = soco
        if (key == '0' || key.contains('a') || key == 'south' || key == 'cross') {
          state.jump = true;
          state.jumpPressedThisFrame = true;
        }
        if (key == '2' || key.contains('x') || key == 'west' || key == 'square') {
          state.punch = true;
          state.punchPressedThisFrame = true;
        }
        // Fallback por índice se nome não bater
        if (key == 'button 0' || key == 'button 2') {
          if (key == 'button 0') {
            state.jump = true;
            state.jumpPressedThisFrame = true;
          } else {
            state.punch = true;
            state.punchPressedThisFrame = true;
          }
        }
      } else if (!isPressed) {
        pressed.remove(key);
        if (key == '0' || key.contains('a') || key == 'south' || key == 'cross' || key == 'button 0') {
          state.jump = false;
        }
        if (key == '2' || key.contains('x') || key == 'west' || key == 'square' || key == 'button 2') {
          state.punch = false;
        }
      }
    } else {
      // Eixo analógico — removido key=='0' que colidia com botão 0
      if (key.contains('left_x') || key.contains('lsx') || key.contains('axis 0') || (key.contains('x') && !key.contains('box') && !key.contains('cross'))) {
        double v = value;
        if (v.abs() < deadZone) v = 0;
        // normaliza - alguns dão 0..1
        if (v > 1) v = 1;
        if (v < -1) v = -1;
        state.x = v.clamp(-1.0, 1.0);
      }
      if (key.contains('hat') || key.contains('dpad')) {
        state.x = value.clamp(-1.0, 1.0);
        if (state.x.abs() < 0.1) state.x = 0;
      }
      if (key == 'dpad_left' && value > 0.5) state.x = -1;
      if (key == 'dpad_right' && value > 0.5) state.x = 1;
    }

    // Replica para _playerInputs se houver correspondência direta
    // Ordena pads por id para mapear 1:1 com humanos
    final idx = _padIndex(padId);
    if (idx >= 0 && idx < _playerInputs.length) {
      final target = _playerInputs[idx];
      // Não sobrescreve se humano também usa teclado - mistura
      target.x = state.x;
      if (state.jumpPressedThisFrame) target.jumpPressedThisFrame = true;
      target.jump = state.jump;
      if (state.punchPressedThisFrame) target.punchPressedThisFrame = true;
      target.punch = state.punch;
    }
  }

  void handleKeyboardPlayer(int playerIndex, {double? x, bool? jump, bool? punch, bool jumpPressed = false, bool punchPressed = false}) {
    if (playerIndex < 0 || playerIndex >= _playerInputs.length) return;
    final t = _playerInputs[playerIndex];
    if (x != null) t.x = x;
    if (jump != null) {
      if (jump && !t.jump) t.jumpPressedThisFrame = true;
      if (jumpPressed) t.jumpPressedThisFrame = true;
      t.jump = jump;
    }
    if (punch != null) {
      if (punch && !t.punch) t.punchPressedThisFrame = true;
      if (punchPressed) t.punchPressedThisFrame = true;
      t.punch = punch;
    }
  }

  void clearFrame() {
    for (final s in inputsByPadId.values) {
      s.clearFrameFlags();
    }
    for (final s in _playerInputs) {
      s.clearFrameFlags();
    }
  }

  void handleDisconnect(String padId) {
    inputsByPadId.remove(padId);
    pressedByPad.remove(padId);
  }

  void dispose() {
    _sub?.cancel();
  }

  void simulatePad(String padId, InputState state) {
    _ensurePad(padId);
    inputsByPadId[padId]!.x = state.x;
    inputsByPadId[padId]!.jump = state.jump;
    inputsByPadId[padId]!.punch = state.punch;
    inputsByPadId[padId]!.jumpPressedThisFrame = state.jumpPressedThisFrame;
    inputsByPadId[padId]!.punchPressedThisFrame = state.punchPressedThisFrame;
  }
}
