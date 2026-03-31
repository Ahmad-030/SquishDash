class BallModel {
  final double x;      // horizontal position -1..1 (0 = center of road)
  final double scaleX; // squish/stretch X
  final double scaleY; // squish/stretch Y

  const BallModel({
    this.x = 0.0,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
  });

  BallModel copyWith({double? x, double? scaleX, double? scaleY}) => BallModel(
    x: x ?? this.x,
    scaleX: scaleX ?? this.scaleX,
    scaleY: scaleY ?? this.scaleY,
  );
}