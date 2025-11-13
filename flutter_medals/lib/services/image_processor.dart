import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/edge_point.dart';

/// Service for processing medal images
class ImageProcessor {
  /// Extract edge points from an image by scanning in polar coordinates
  static List<EdgePoint> extractEdgePoints(img.Image image, {int angleSteps = 120}) {
    final centerX = image.width / 2;
    final centerY = image.height / 2;
    final maxRadius = max(image.width, image.height) / 2;
    
    final edgePoints = <EdgePoint>[];
    
    for (int i = 0; i < angleSteps; i++) {
      final angle = (i / angleSteps) * pi * 2;
      final dx = cos(angle);
      final dy = sin(angle);
      
      double maxFoundRadius = 0;
      
      // Cast ray from center outward
      for (double r = 0; r < maxRadius; r++) {
        final x = (centerX + dx * r).floor();
        final y = (centerY + dy * r).floor();
        
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          final pixel = image.getPixel(x, y);
          final alpha = pixel.a;
          
          if (alpha > 128) {
            maxFoundRadius = r;
          }
        }
      }
      
      edgePoints.add(EdgePoint.fromPolar(
        centerX,
        centerY,
        angle,
        maxFoundRadius,
      ));
    }
    
    return edgePoints;
  }

  /// Create a silver/desaturated version of an image
  /// Back face will be flipped during rendering with -scaleX
  static img.Image createSilverVersion(img.Image original) {
    final silver = img.Image.from(original);
    
    // Apply silver effect
    for (int y = 0; y < silver.height; y++) {
      for (int x = 0; x < silver.width; x++) {
        final pixel = silver.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        final a = pixel.a;
        
        // Convert to grayscale with slight silver tint
        final gray = r * 0.299 + g * 0.587 + b * 0.114;
        
        final newR = min(255, (gray * 0.95 + 20).round());
        final newG = min(255, (gray * 0.97 + 20).round());
        final newB = min(255, (gray + 25).round());
        
        silver.setPixel(x, y, img.ColorRgba8(newR, newG, newB, a.toInt()));
      }
    }
    
    return silver;
  }

  /// Convert img.Image to ui.Image for Flutter rendering
  static Future<ui.Image> convertToUIImage(img.Image image) async {
    final bytes = img.encodePng(image);
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Load image from asset path
  static Future<img.Image> loadImageFromAsset(String path, BuildContext context) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    final bytes = data.buffer.asUint8List();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image: $path');
    }
    return image;
  }

  /// Create a lightness mask for shine effect
  static img.Image createLightnessMask(img.Image original, double maskContrast) {
    final mask = img.Image(width: original.width, height: original.height);
    
    for (int y = 0; y < mask.height; y++) {
      for (int x = 0; x < mask.width; x++) {
        final pixel = original.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        final alpha = pixel.a;
        
        if (alpha < 128) {
          // Transparent pixel - keep transparent in mask
          mask.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
        } else {
          // Calculate lightness
          final lightness = (r * 0.299 + g * 0.587 + b * 0.114) / 255.0;
          final contrasty = pow(lightness, maskContrast);
          final value = (contrasty * 255).round();
          final alphaNormalized = alpha / 255.0;
          final maskAlpha = (alphaNormalized * contrasty * 255).round();
          
          mask.setPixel(x, y, img.ColorRgba8(value, value, value, maskAlpha));
        }
      }
    }
    
    return mask;
  }
}

