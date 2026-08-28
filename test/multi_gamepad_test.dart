import 'package:flutter_test/flutter_test.dart';
import 'package:stumble_brawl/src/input/input_state.dart';
import 'package:stumble_brawl/src/input/multi_gamepad.dart';

void main() {
  group('MultiGamepadManager', () {
    test('initial connectedCount 0', () {
      final inputs = [InputState()];
      final m = MultiGamepadManager(inputs);
      expect(m.connectedCount, 0);
    });

    test('simulatePad creates entry', () {
      final inputs = [InputState(), InputState()];
      final m = MultiGamepadManager(inputs);
      final s = InputState()..x = 0.5..jump = true;
      m.simulatePad('pad1', s);
      expect(m.connectedCount, 1);
      expect(m.inputsByPadId['pad1']!.x, 0.5);
    });

    test('handleKeyboardPlayer updates', () {
      final inputs = [InputState()];
      final m = MultiGamepadManager(inputs);
      m.handleKeyboardPlayer(0, x: 0.8, jump: true, jumpPressed: true);
      expect(inputs[0].x, 0.8);
      expect(inputs[0].jump, true);
      expect(inputs[0].jumpPressedThisFrame, true);
      m.clearFrame();
      expect(inputs[0].jumpPressedThisFrame, false);
    });

    test('handleKeyboardPlayer out of range ignored', () {
      final inputs = [InputState()];
      final m = MultiGamepadManager(inputs);
      m.handleKeyboardPlayer(5, x: 1);
      expect(inputs[0].x, 0);
    });

    test('clearFrame clears all', () {
      final inputs = [InputState()..jumpPressedThisFrame = true];
      final m = MultiGamepadManager(inputs);
      m.simulatePad('p', InputState()..jumpPressedThisFrame = true);
      m.clearFrame();
      expect(inputs[0].jumpPressedThisFrame, false);
      expect(m.inputsByPadId['p']!.jumpPressedThisFrame, false);
    });

    test('dispose does not throw', () {
      final m = MultiGamepadManager([InputState()]);
      m.dispose();
    });

    test('onPadConnected callback', () {
      final inputs = [InputState()];
      bool called = false;
      final m = MultiGamepadManager(inputs, onPadConnected: () => called = true);
      m.simulatePad('a', InputState());
      expect(called, true);
    });
  });
}
