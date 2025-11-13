import 'dart:math';

/// Represents a point on the edge of a medal in polar coordinates
class EdgePoint {
  final double angle;
  final double radius;
  final double x;
  final double y;

  EdgePoint({
    required this.angle,
    required this.radius,
    required this.x,
    required this.y,
  });

  /// Create an edge point from center and polar coordinates
  factory EdgePoint.fromPolar(
    double centerX,
    double centerY,
    double angle,
    double radius,
  ) {
    final dx = cos(angle);
    final dy = sin(angle);
    return EdgePoint(
      angle: angle,
      radius: radius,
      x: centerX + dx * radius,
      y: centerY + dy * radius,
    );
  }
}


