// Each obstacle is an orange brick wall with a rectangular hole cut out.
// The hole position (holeLeft, holeTop) and size (holeWidth, holeHeight)
// define where the ball must pass through.
// z is the world-depth position (increases as obstacles spawn further away).

class ObstacleModel {
  double z; // world Z position (depth), decreases each frame as it approaches
  final double holeLeft;   // left edge of hole, in world X units (-1..1 range, 0=center)
  final double holeRight;  // right edge of hole
  final double holeBottom; // bottom of hole in world Y (0=ground, 1=top of wall)
  final double holeTop;    // top of hole
  bool passed;

  ObstacleModel({
    required this.z,
    required this.holeLeft,
    required this.holeRight,
    required this.holeBottom,
    required this.holeTop,
    this.passed = false,
  });
}