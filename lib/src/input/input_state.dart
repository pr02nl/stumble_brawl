/// Estado unificado de input - funciona para touch e gamepad
class InputState {
  double x = 0.0; // -1 esquerda, 1 direita
  bool jump = false;
  bool punch = false;
  bool jumpPressedThisFrame = false;
  bool punchPressedThisFrame = false;

  void clearFrameFlags() {
    jumpPressedThisFrame = false;
    punchPressedThisFrame = false;
  }

  void copyFrom(InputState other) {
    x = other.x;
    jump = other.jump;
    punch = other.punch;
  }
}
