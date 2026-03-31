enum ShapeType { rectangle, circle, diamond }

class ObstacleModel {
  double x;
  final double gapX;
  final double gapY;
  final double gapWidth;
  final double gapHeight;
  final ShapeType shapeType;

  ObstacleModel({
    required this.x,
    required this.gapX,
    required this.gapY,
    required this.gapWidth,
    required this.gapHeight,
    required this.shapeType,
  });
}
