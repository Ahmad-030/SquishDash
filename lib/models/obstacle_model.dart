import '../controllers/game_controller.dart';

// Each obstacle is an orange brick wall with a rectangular hole cut out.
// holeType tells the player what shape they need to pass through.

class ObstacleModel {
  double z;
  final double holeLeft;
  final double holeRight;
  final double holeBottom = 0.0; // always ground level — ball cannot jump
  final double holeTop;
  final HoleType holeType;
  bool passed;

  ObstacleModel({
    required this.z,
    required this.holeLeft,
    required this.holeRight,
    required this.holeTop,
    this.holeType = HoleType.normal,
    this.passed = false,
  });
}