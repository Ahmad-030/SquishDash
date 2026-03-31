class JellyModel {
  final double x;
  final double y;
  final double width;
  final double height;

  JellyModel({
    this.x = 200,
    this.y = 400,
    this.width = 60,
    this.height = 60,
  });

  JellyModel copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return JellyModel(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
