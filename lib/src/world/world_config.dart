import 'package:flame/components.dart';

/// Config centralizada do mundo — evita hardcodes 900x600 / y>850 espalhados.
class WorldConfig {
  static const double width = 900;
  static const double height = 600;
  static const double killY = 850;
  static const double groundY = 500;
  static const double platformHeight = 22;
  static final Vector2 playerSize = Vector2(36, 44);

  static Vector2 worldSize = Vector2(width, height);
}
