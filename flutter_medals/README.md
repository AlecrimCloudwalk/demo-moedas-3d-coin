# 3D Medal Demo - Flutter Implementation

A complete Flutter implementation of the 3D medal rotation proof of concept, featuring realistic 3D depth effects with irregular edge detection.

## Features

- **3D Medal Rotation**: Smooth rotation animation with realistic depth perception
- **Irregular Edge Detection**: Automatically detects medal outlines in polar coordinates
- **Dynamic Edge Rendering**: Creates authentic 3D thickness that follows the medal's shape
- **Silver Back Face**: Automatically generated desaturated back side for coin effect
- **Interactive Controls**: 
  - Rotation angle slider
  - Medal thickness adjustment
  - Edge darkness control
  - Animation speed control
- **Medal Library**: Browse and switch between multiple medals
- **Tap to Flip**: Click any medal to flip it 180° with smooth animation
- **Dark Mode**: Toggle between light and dark themes

## How to Run

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)

### Installation

1. Navigate to the Flutter project directory:
```bash
cd "flutter_medals"
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For web
flutter run -d chrome

# For macOS
flutter run -d macos

# For iOS (requires macOS with Xcode)
flutter run -d ios

# For Android (requires Android Studio setup)
flutter run -d android
```

## Project Structure

```
flutter_medals/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── models/
│   │   └── edge_point.dart        # Edge point data model
│   ├── services/
│   │   └── image_processor.dart   # Image processing utilities
│   ├── widgets/
│   │   └── medal_3d.dart          # 3D medal widget with CustomPainter
│   └── screens/
│       └── medal_demo_screen.dart # Main demo screen
├── assets/
│   └── images/                    # Medal image assets
└── pubspec.yaml                   # Dependencies
```

## Technical Details

### Edge Detection Algorithm

The app uses a polar coordinate scanning algorithm to detect irregular edges:

1. **Ray Casting**: Casts rays from the medal center at multiple angles (120 steps)
2. **Alpha Detection**: For each ray, finds the furthest pixel with alpha > 128
3. **Edge Points**: Stores these points as polar coordinates (angle, radius)
4. **3D Extrusion**: Connects edge points to create realistic side faces

### Rendering Pipeline

1. **Image Processing**: Loads PNG images and analyzes alpha channel
2. **Silver Generation**: Creates desaturated back face using grayscale conversion
3. **CustomPainter**: Renders 3D effect using Flutter's Canvas API
4. **Painter's Algorithm**: Draws faces back-to-front for correct occlusion

### Performance Optimizations

- Cached edge point calculations
- Efficient CustomPainter with `shouldRepaint` optimization
- High-quality image filtering
- Hardware-accelerated rendering

## Dependencies

- **flutter**: UI framework
- **image**: Image manipulation and processing
- **vector_math**: 3D math utilities

## Customization

### Adding New Medals

1. Add your medal PNG images to `assets/images/`
2. Update the `medalImages` list in `medal_demo_screen.dart`:

```dart
static const medalImages = [
  'assets/images/your_medal.png',
  // ... add more medals
];
```

### Adjusting Edge Detection

Modify the `angleSteps` parameter in `image_processor.dart`:

```dart
// More steps = smoother edges but slower processing
final edgePoints = ImageProcessor.extractEdgePoints(
  originalImage,
  angleSteps: 120, // Increase for more detail
);
```

## Building for Production

### Web
```bash
flutter build web
```

### iOS
```bash
flutter build ios --release
```

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### macOS
```bash
flutter build macos --release
```

## Troubleshooting

### Images not loading
- Ensure images are in `assets/images/`
- Check that `pubspec.yaml` includes the assets path
- Run `flutter clean` and `flutter pub get`

### Performance issues
- Reduce `angleSteps` in edge detection (default: 120)
- Disable animations on slower devices
- Use lower resolution images

## Comparison with Web Version

| Feature | Web (CSS/Canvas) | Flutter |
|---------|------------------|---------|
| 3D Transforms | CSS 3D transforms | CustomPainter + Transform |
| Edge Detection | Canvas API | dart:ui + image package |
| Performance | Good on modern browsers | Excellent (native) |
| Cross-platform | Web only | iOS, Android, Web, Desktop |
| Code reuse | JavaScript | Dart (type-safe) |

## Future Enhancements

- [ ] Add shine/reflection effects based on rotation
- [ ] Implement physics-based momentum on drag
- [ ] Add medal collection/achievements system
- [ ] Support for video textures
- [ ] WebGL/Skia 3D rendering backend
- [ ] Multiplayer medal showcase

## License

This is a proof of concept for educational purposes.

## Credits

Converted from HTML/CSS/JavaScript proof of concept to Flutter by Cursor AI.


