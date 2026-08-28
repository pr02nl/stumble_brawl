import 'package:flame/components.dart';

// Buffer circular 8s — Fase 4 clip share
// Armazena snapshots para replay/share via share_plus

class FrameSnapshot {
  final double time;
  final List<Vector2> positions;
  final List<double> damages;
  FrameSnapshot({required this.time, required this.positions, required this.damages});
}

class ReplayBuffer {
  final int maxFrames = 240; // 8s @30fps
  final List<FrameSnapshot> _frames = [];

  void record(double time, List<Vector2> pos, List<double> dmg) {
    _frames.add(FrameSnapshot(time: time, positions: List.from(pos), damages: List.from(dmg)));
    if (_frames.length > maxFrames) _frames.removeAt(0);
  }

  List<FrameSnapshot> get frames => List.unmodifiable(_frames);
  void clear() => _frames.clear();
  int get length => _frames.length;
}
