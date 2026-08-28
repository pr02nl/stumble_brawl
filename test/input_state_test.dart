import 'package:flutter_test/flutter_test.dart';
import 'package:stumble_brawl/src/input/input_state.dart';

void main() {
  group('InputState', () {
    test('initial values', () {
      final s = InputState();
      expect(s.x, 0.0);
      expect(s.jump, false);
      expect(s.punch, false);
      expect(s.jumpPressedThisFrame, false);
      expect(s.punchPressedThisFrame, false);
    });

    test('clearFrameFlags resets', () {
      final s = InputState()
        ..jumpPressedThisFrame = true
        ..punchPressedThisFrame = true;
      s.clearFrameFlags();
      expect(s.jumpPressedThisFrame, false);
      expect(s.punchPressedThisFrame, false);
      expect(s.jump, false); // ensure not cleared? Actually only flags cleared, jump stays as is? But test expects jump still false? InputState jump not cleared by clearFrameFlags
      s.jump = true;
      s.punch = true;
      s.jumpPressedThisFrame = true;
      s.clearFrameFlags();
      expect(s.jump, true);
      expect(s.punch, true);
    });

    test('copyFrom copies x jump punch', () {
      final a = InputState()..x = 0.7..jump = true..punch = true;
      final b = InputState();
      b.copyFrom(a);
      expect(b.x, 0.7);
      expect(b.jump, true);
      expect(b.punch, true);
    });

    test('x clamp simulation', () {
      final s = InputState()..x = -1.5;
      // logic in gamepad is clamp, but InputState itself doesn't clamp - verify raw
      expect(s.x, -1.5);
      s.x = 1.5;
      expect(s.x, 1.5);
    });

    test('press frame flags workflow', () {
      final s = InputState();
      s.jump = true;
      s.jumpPressedThisFrame = true;
      expect(s.jumpPressedThisFrame, true);
      s.clearFrameFlags();
      expect(s.jumpPressedThisFrame, false);
      expect(s.jump, true); // still held
      s.jump = false;
      expect(s.jump, false);
    });
  });
}
