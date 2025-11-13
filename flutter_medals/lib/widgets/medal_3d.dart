import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/edge_point.dart';

/// Widget that displays a 3D rotatable medal
class Medal3D extends StatefulWidget {
  final ui.Image frontImage;
  final ui.Image backImage;
  final List<EdgePoint> edgePoints;
  final double rotation;
  final double thickness;
  final double edgeDarkness;
  final bool showEdge;
  final VoidCallback? onTap;
  final double size;
  final double shineOpacity;
  final double shineAngle;

  const Medal3D({
    super.key,
    required this.frontImage,
    required this.backImage,
    required this.edgePoints,
    required this.rotation,
    this.thickness = 15.0,
    this.edgeDarkness = 0.4,
    this.showEdge = true,
    this.onTap,
    this.size = 300,
    this.shineOpacity = 0.8,
    this.shineAngle = 135,
  });

  @override
  State<Medal3D> createState() => _Medal3DState();
}

class _Medal3DState extends State<Medal3D> {
  ui.Image? _shineMask;
  List<({double px, double py, double npx, double npy})>? _cachedEdgeCoords; // Pre-computed coordinates
  List<double>? _cachedSegmentAngles; // Pre-computed segment angles
  
  @override
  void initState() {
    super.initState();
    _generateShineMask();
    _precomputeEdgeCoords();
  }

  @override
  void didUpdateWidget(Medal3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frontImage != widget.frontImage) {
      _generateShineMask();
    }
    if (oldWidget.edgePoints != widget.edgePoints) {
      _precomputeEdgeCoords();
    }
  }

  void _precomputeEdgeCoords() {
    if (widget.edgePoints.isEmpty) return;
    
    final centerX = widget.frontImage.width / 2;
    final centerY = widget.frontImage.height / 2;
    
    _cachedEdgeCoords = [];
    _cachedSegmentAngles = [];
    
    for (int i = 0; i < widget.edgePoints.length; i++) {
      final point = widget.edgePoints[i];
      final nextPoint = widget.edgePoints[(i + 1) % widget.edgePoints.length];
      
      // Convert to centered coordinates (base coords, no rotation transforms)
      final px = (point.x - centerX);
      final py = (point.y - centerY);
      final npx = (nextPoint.x - centerX);
      final npy = (nextPoint.y - centerY);
      
      // Cache coordinates directly (much faster than Path extraction)
      _cachedEdgeCoords!.add((px: px, py: py, npx: npx, npy: npy));
      
      // Pre-compute segment angle
      final segmentAngle = (i / widget.edgePoints.length) * pi * 2;
      _cachedSegmentAngles!.add(segmentAngle);
    }
  }

  Future<void> _generateShineMask() async {
    // Convert ui.Image to img.Image for processing
    final byteData = await widget.frontImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;

    final buffer = byteData.buffer.asUint8List();
    final originalImage = img.Image.fromBytes(
      width: widget.frontImage.width,
      height: widget.frontImage.height,
      bytes: buffer.buffer,
      format: img.Format.uint8,
      numChannels: 4,
    );

    // Create lightness mask with strict alpha preservation
    final mask = img.Image(width: originalImage.width, height: originalImage.height);
    
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        final pixel = originalImage.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final alpha = pixel.a.toInt();

        if (alpha < 10) {
          // Fully transparent pixels - no shine
          mask.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
        } else {
          // Calculate lightness and apply contrast
          final lightness = (r * 0.299 + g * 0.587 + b * 0.114) / 255;
          final contrasted = pow(lightness, 0.5);
          final value = (contrasted * 255).toInt();
          
          // Use the ORIGINAL alpha directly to preserve medal edges
          mask.setPixel(x, y, img.ColorRgba8(value, value, value, alpha));
        }
      }
    }

    // Convert back to ui.Image
    final codec = await ui.instantiateImageCodec(img.encodePng(mask));
    final frame = await codec.getNextFrame();
    
    if (mounted) {
      setState(() {
        _shineMask = frame.image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: Medal3DPainter(
            frontImage: widget.frontImage,
            backImage: widget.backImage,
            edgePoints: widget.edgePoints,
            rotation: widget.rotation,
            thickness: widget.thickness,
            edgeDarkness: widget.edgeDarkness,
            showEdge: widget.showEdge,
            shineMask: _shineMask,
            shineOpacity: widget.shineOpacity,
            shineAngle: widget.shineAngle,
            cachedEdgeCoords: _cachedEdgeCoords,
            cachedSegmentAngles: _cachedSegmentAngles,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for rendering the 3D medal
class Medal3DPainter extends CustomPainter {
  final ui.Image frontImage;
  final ui.Image backImage;
  final List<EdgePoint> edgePoints;
  final double rotation;
  final double thickness;
  final double edgeDarkness;
  final bool showEdge;
  final ui.Image? shineMask;
  final double shineOpacity;
  final double shineAngle;
  final List<({double px, double py, double npx, double npy})>? cachedEdgeCoords; // Pre-computed coordinates
  final List<double>? cachedSegmentAngles; // Pre-computed angles

  Medal3DPainter({
    required this.frontImage,
    required this.backImage,
    required this.edgePoints,
    required this.rotation,
    required this.thickness,
    required this.edgeDarkness,
    required this.showEdge,
    this.shineMask,
    this.shineOpacity = 0.8,
    this.shineAngle = 135,
    this.cachedEdgeCoords,
    this.cachedSegmentAngles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);

    // Calculate scale based on rotation
    double normalizedRotation = ((rotation % 360) + 360) % 360;
    if (normalizedRotation > 180) normalizedRotation -= 360;

    final rotRad = (normalizedRotation * pi) / 180;
    final scaleX = cos(rotRad);
    final absScaleX = scaleX.abs();

    // Calculate proper face offsets (simulating Z-depth in 2D)
    // Rotate around the CENTER of the medal's thickness
    // Front and back faces move symmetrically from center
    final edgeVisibility = 1 - absScaleX; // 0 at face-on, 1 at edge-on
    final edgeDirection = normalizedRotation > 0 ? 1.0 : -1.0;
    
    final halfThickness = thickness / 2;
    
    // At 0 degrees (face-on): both faces at position 0 (collapsed)
    // At 90 degrees (edge-on): front at +thickness/2, back at -thickness/2
    // They move symmetrically around the center (position 0)
    final frontOffset = halfThickness * edgeVisibility * edgeDirection;
    final backOffset = -halfThickness * edgeVisibility * edgeDirection;

    // Determine which faces are visible
    final frontVisible = normalizedRotation >= -90 && normalizedRotation <= 90;

    // Scale factor for image to canvas
    final imageWidth = frontImage.width.toDouble();
    final imageHeight = frontImage.height.toDouble();
    final scaleFactor = size.width / max(imageWidth, imageHeight);

    // PAINTER'S ALGORITHM: Draw back to front
    // Front visible from -90° to 90°, back visible outside that range
    if (frontVisible) {
      // Front is visible - draw back to front
      // Back face should NEVER be visible when viewing from front side (backface culling)

      // 1. Edge (connects front and back, only if edge is showing)
      if (showEdge && absScaleX < 0.98) {
        _drawEdge(
          canvas,
          scaleX,
          edgeDirection,
          thickness,
          frontOffset,
          backOffset,
          scaleFactor,
        );
      }

      // 2. Front face (closest, always drawn when in range)
      _drawImageFace(
        canvas,
        frontImage,
        scaleX: scaleX,
        translateX: frontOffset,
        scaleFactor: scaleFactor,
      );
      
      // 3. Shine effect on front face
      if (shineMask != null && shineOpacity > 0) {
        _drawShine(
          canvas,
          scaleX,
          frontOffset,
          scaleFactor,
          size,
          image: frontImage, // Use front image for clipping
        );
      }
    } else {
      // Back is visible - draw back to front
      // Front face should NEVER be visible when viewing from back side (backface culling)

      // 1. Edge (connects front and back, only if edge is showing)
      if (showEdge && absScaleX < 0.98) {
        _drawEdge(
          canvas,
          scaleX,
          edgeDirection,
          thickness,
          frontOffset,
          backOffset,
          scaleFactor,
        );
      }

      // 2. Back face (closest, always drawn when in range)
      _drawImageFace(
        canvas,
        backImage,
        scaleX: scaleX, // Same scaleX - naturally mirrored
        translateX: backOffset,
        scaleFactor: scaleFactor,
      );
      
      // 3. Shine effect on back face
      if (shineMask != null && shineOpacity > 0) {
        _drawShine(
          canvas,
          scaleX,
          backOffset,
          scaleFactor,
          size,
          image: backImage, // Use back image for clipping
        );
      }
    }

    canvas.restore();
  }

  void _drawImageFace(
    Canvas canvas,
    ui.Image image, {
    required double scaleX,
    required double translateX,
    required double scaleFactor,
  }) {
    canvas.save();
    canvas.translate(translateX, 0);
    canvas.scale(scaleX * scaleFactor, scaleFactor);

    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    canvas.drawImage(
      image,
      Offset(-imageWidth / 2, -imageHeight / 2),
      paint,
    );

    canvas.restore();
  }

  void _drawEdge(
    Canvas canvas,
    double scaleX,
    double edgeDirection,
    double thickness,
    double frontOffset,
    double backOffset,
    double scaleFactor,
  ) {
    if (thickness < 0.5) return;

    // Use cached coordinates if available, otherwise fall back to computing on-the-fly
    final useCache = cachedEdgeCoords != null && 
                     cachedSegmentAngles != null &&
                     cachedEdgeCoords!.length == edgePoints.length;

    // Calculate light offset based on rotation (moving gradient effect)
    final lightOffset = (rotation / 360) * pi * 2;

    for (int i = 0; i < edgePoints.length; i++) {
      double px, py, npx, npy;
      
      if (useCache) {
        // Use cached coordinates directly (much faster!)
        final coords = cachedEdgeCoords![i];
        px = coords.px;
        py = coords.py;
        npx = coords.npx;
        npy = coords.npy;
      } else {
        // Fallback: compute on-the-fly
        final centerX = frontImage.width / 2;
        final centerY = frontImage.height / 2;
        final point = edgePoints[i];
        final nextPoint = edgePoints[(i + 1) % edgePoints.length];
        px = (point.x - centerX);
        py = (point.y - centerY);
        npx = (nextPoint.x - centerX);
        npy = (nextPoint.y - centerY);
      }
      
      // BACKFACE CULLING: Only draw segments facing the camera
      final segmentX = (px + npx) / 2;
      
      double normalizedRot = ((rotation % 360) + 360) % 360;
      if (normalizedRot > 180) {
        normalizedRot -= 360;
      }
      
      if (normalizedRot.abs() > 10) {
        final onVisibleSide = (normalizedRot > 0 && segmentX < 0) || 
                              (normalizedRot < 0 && segmentX > 0);
        if (!onVisibleSide) {
          continue;
        }
      }

      // Scale and transform for drawing
      final pxScaled = px * scaleFactor;
      final pyScaled = py * scaleFactor;
      final npxScaled = npx * scaleFactor;
      final npyScaled = npy * scaleFactor;

      // Four corners of the quad
      final x1 = pxScaled * scaleX + frontOffset;
      final y1 = pyScaled;
      final x2 = npxScaled * scaleX + frontOffset;
      final y2 = npyScaled;
      final x3 = npxScaled * scaleX + backOffset;
      final y3 = npyScaled;
      final x4 = pxScaled * scaleX + backOffset;
      final y4 = pyScaled;

      final path = Path()
        ..moveTo(x1, y1)
        ..lineTo(x2, y2)
        ..lineTo(x3, y3)
        ..lineTo(x4, y4)
        ..close();

      // Use cached segment angle if available
      final segmentAngle = useCache 
          ? cachedSegmentAngles![i]
          : (i / edgePoints.length) * pi * 2;
      final lightAngle = segmentAngle + lightOffset;

      // Moving gradient effect (like CSS version)
      final mainReflection = pow(sin(lightAngle) * 0.5 + 0.5, 1.5).toDouble();
      final detailReflection = sin(lightAngle * 5) * 0.25;
      final highlight = pow(max(0.0, sin(lightAngle)), 32).toDouble() * 0.5;

      final reflectionValue = mainReflection + detailReflection + highlight;
      final baseLightness = 25 + (reflectionValue * 75);
      final adjustedLightness = baseLightness * (1 - edgeDarkness * 0.5);
      final brightness = (adjustedLightness / 100 * 255).floor();
      
      final paint = Paint()
        ..color = Color.fromARGB(255, brightness.clamp(0, 255), brightness.clamp(0, 255), brightness.clamp(0, 255))
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high
        ..blendMode = BlendMode.srcOver;

      canvas.drawPath(path, paint);

      final strokePaint = Paint()
        ..color = const Color.fromARGB(51, 0, 0, 0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..isAntiAlias = true;

      canvas.drawPath(path, strokePaint);
    }
  }

  void _drawShine(
    Canvas canvas,
    double scaleX,
    double faceOffset,
    double scaleFactor,
    Size size, {
    required ui.Image image, // Image to use for clipping (front or back)
  }) {
    canvas.save();
    
    // Apply rotation scaling and offset
    canvas.scale(scaleX, 1.0);
    canvas.translate(faceOffset, 0);

    // Normalize rotation to -180 to 180
    double normalizedAngle = ((rotation + 180) % 360) - 180;
    if (normalizedAngle == 180) normalizedAngle = -180;

    // Map rotation to shine position (sweeps twice: -90 to 0, then 0 to 90)
    double angleForPosition = ((normalizedAngle + 90) % 180);
    if (angleForPosition < 0) angleForPosition += 180;
    angleForPosition -= 90;

    double bgPosition;
    if (angleForPosition >= -90 && angleForPosition <= 0) {
      // First pass: -90° to 0° → 0% to 25%
      bgPosition = ((angleForPosition + 90) / 90) * 0.25;
    } else if (angleForPosition > 0 && angleForPosition <= 90) {
      // Second pass: 0° to 90° → 25% to 100%
      bgPosition = 0.25 + (angleForPosition / 90) * 0.75;
    } else {
      bgPosition = angleForPosition < -90 ? 0.0 : 1.0;
    }

    // Calculate image dimensions
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final imageSize = max(imageWidth, imageHeight);
    final scale = size.width / imageSize;

    final drawWidth = imageWidth * scale;
    final drawHeight = imageHeight * scale;
    final drawX = -drawWidth / 2;
    final drawY = -drawHeight / 2;
    
    // Create gradient shader
    final shineAngleRad = shineAngle * pi / 180;
    final gradientSize = sqrt(drawWidth * drawWidth + drawHeight * drawHeight) * 2;
    
    // Calculate gradient direction
    final dx = cos(shineAngleRad);
    final dy = sin(shineAngleRad);
    
    // Position the gradient based on rotation (sweep effect)
    final offset = (bgPosition - 0.5) * gradientSize * 4;
    final centerX = offset * dx;
    final centerY = offset * dy;
    
    final gradientStart = Offset(centerX - dx * gradientSize, centerY - dy * gradientSize);
    final gradientEnd = Offset(centerX + dx * gradientSize, centerY + dy * gradientSize);

    final gradient = ui.Gradient.linear(
      gradientStart,
      gradientEnd,
      [
        Colors.transparent,
        Colors.transparent,
        Colors.white.withValues(alpha: 0.5 * shineOpacity),
        Colors.white.withValues(alpha: shineOpacity),
        Colors.white.withValues(alpha: 0.5 * shineOpacity),
        Colors.transparent,
        Colors.transparent,
      ],
      [0.0, 0.40, 0.45, 0.50, 0.55, 0.60, 1.0],
    );

    // CRITICAL: Draw shine and clip it using the medal's alpha channel
    // We DON'T draw the medal here - it's already drawn in paint() method
    canvas.saveLayer(Rect.fromLTWH(drawX, drawY, drawWidth, drawHeight), Paint());
    
    // Step 1: Draw the shine gradient with adaptive blur
    // Reduce blur when opacity is low for better performance
    final blurSigma = shineOpacity > 0.5 ? 15.0 : (shineOpacity * 30).clamp(5.0, 15.0);
    final paint = Paint()..shader = gradient;
    if (blurSigma > 5.0) {
      paint.imageFilter = ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);
    }
    canvas.drawRect(
      Rect.fromLTWH(drawX, drawY, drawWidth, drawHeight),
      paint,
    );
    
    // Step 2: Clip to medal's alpha using dstIn - this removes shine outside medal bounds
    canvas.drawImageRect(
      image, // Use the provided image (front or back) for clipping
      Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      Rect.fromLTWH(drawX, drawY, drawWidth, drawHeight),
      Paint()..blendMode = BlendMode.dstIn, // Clip shine to medal's alpha
    );
    
    // Step 3: Optionally modulate with shine mask for brightness variation
    if (shineMask != null) {
      canvas.drawImageRect(
        shineMask!,
        Rect.fromLTWH(0, 0, shineMask!.width.toDouble(), shineMask!.height.toDouble()),
        Rect.fromLTWH(drawX, drawY, drawWidth, drawHeight),
        Paint()..blendMode = BlendMode.modulate,
      );
    }
    
    canvas.restore(); // End compositing layer
    canvas.restore(); // End canvas save
  }

  @override
  bool shouldRepaint(Medal3DPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.thickness != thickness ||
        oldDelegate.edgeDarkness != edgeDarkness ||
        oldDelegate.showEdge != showEdge ||
        oldDelegate.frontImage != frontImage ||
        oldDelegate.backImage != backImage ||
        oldDelegate.shineMask != shineMask ||
        oldDelegate.shineOpacity != shineOpacity ||
        oldDelegate.shineAngle != shineAngle;
  }
}

