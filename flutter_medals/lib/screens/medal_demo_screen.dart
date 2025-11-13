import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/edge_point.dart';
import '../services/image_processor.dart';
import '../widgets/medal_3d.dart';

class MedalDemoScreen extends StatefulWidget {
  const MedalDemoScreen({super.key});

  @override
  State<MedalDemoScreen> createState() => _MedalDemoScreenState();
}

class _MedalDemoScreenState extends State<MedalDemoScreen>
    with SingleTickerProviderStateMixin {
  // Medal images
  static const medalImages = [
    'assets/images/Badge_conquistas_arte_da_persistencia_001.png',
    'assets/images/Badge_conquistas_ativando_a_chama_001.png',
    'assets/images/Badge_conquistas_bug_001.png',
    'assets/images/Badge_conquistas_crescendo_com_pix_001.png',
    'assets/images/Badge_conquistas_crescendo_tap_002.png',
    'assets/images/Badge_conquistas_espalhando_a_semente_001.png',
    'assets/images/Badge_conquistas_farol_001.png',
    'assets/images/Badge_conquistas_jim_001.png',
    'assets/images/Badge_conquistas_link_001.png',
    'assets/images/Badge_conquistas_mestre_dos_cartoes_002.png',
    'assets/images/Badge_conquistas_regador_001.png',
  ];

  // State
  int _currentMedalIndex = 0;
  ui.Image? _frontImage;
  ui.Image? _backImage;
  List<EdgePoint>? _edgePoints;
  bool _isLoading = true;

  // Controls
  double _rotation = 0;
  double _thickness = 15;
  double _edgeDarkness = 0.4;
  double _animationSpeed = 0.5;
  bool _showEdge = true;
  bool _isDarkMode = false;

  // Animation
  AnimationController? _animationController; // For flip animation
  bool _isAnimating = false;
  double _currentVelocity = 0.0; // Current rotation velocity for easing
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Faster, more snappy
    );
    _loadMedal(_currentMedalIndex);
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadMedal(int index) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load original image
      final originalImage =
          await ImageProcessor.loadImageFromAsset(medalImages[index], context);

      // Extract edge points
      final edgePoints = ImageProcessor.extractEdgePoints(originalImage);

      // Create silver back (now horizontally flipped)
      final silverImage = ImageProcessor.createSilverVersion(originalImage);

      // Convert to UI images
      final frontImage = await ImageProcessor.convertToUIImage(originalImage);
      final backImage = await ImageProcessor.convertToUIImage(silverImage);

      setState(() {
        _frontImage = frontImage;
        _backImage = backImage;
        _edgePoints = edgePoints;
        _currentMedalIndex = index;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading medal: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startAnimation() {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
      _currentVelocity = 0.0; // Reset for smooth ease-in
      _lastFrameTime = DateTime.now();
    });

    void animate() {
      if (!_isAnimating) return;
      
      final now = DateTime.now();
      final deltaTime = _lastFrameTime != null 
          ? now.difference(_lastFrameTime!).inMilliseconds / 16.0
          : 1.0;
      _lastFrameTime = now;

      setState(() {
        // Ease in: gradually increase velocity to target speed
        final targetVelocity = _animationSpeed;
        const easeInSpeed = 0.15; // How fast to ease in (lower = smoother)
        _currentVelocity += (targetVelocity - _currentVelocity) * easeInSpeed;
        
        // Apply velocity
        _rotation += _currentVelocity * deltaTime;
        
        // Wrap rotation
        if (_rotation > 180) _rotation = -180;
        if (_rotation < -180) _rotation = 180;
      });
      
      // Use SchedulerBinding for frame-synced updates (better than Future.delayed)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isAnimating) {
          animate();
        }
      });
    }

    animate();
  }

  void _stopAnimation() {
    if (!_isAnimating) return;
    
    final startVelocity = _currentVelocity;
    
    setState(() {
      _isAnimating = false;
    });

    // Ease out animation: gradually slow down to stop
    void easeOut() {
      setState(() {
        // Exponential ease out
        _currentVelocity *= 0.85; // Decay factor
        _rotation += _currentVelocity;
        
        // Wrap rotation
        if (_rotation > 180) _rotation -= 360;
        if (_rotation < -180) _rotation += 360;
      });

      // Continue easing until velocity is very small
      if (_currentVelocity.abs() > 0.01) {
        Future.delayed(const Duration(milliseconds: 16), easeOut);
      } else {
        setState(() {
          _currentVelocity = 0.0;
        });
      }
    }

    // Only ease out if there was velocity
    if (startVelocity.abs() > 0.01) {
      easeOut();
    } else {
      setState(() {
        _currentVelocity = 0.0;
      });
    }
  }

  void _reset() {
    setState(() {
      _isAnimating = false;
      _currentVelocity = 0.0;
      _rotation = 0;
    });
  }

  Animation<double>? _flipAnimation;

  void _flip() {
    final controller = _animationController;
    if (controller == null || controller.isAnimating) return;

    // Pause continuous animation if it's running
    final wasAnimating = _isAnimating;
    if (_isAnimating) {
      setState(() {
        _isAnimating = false;
      });
    }

    final startRotation = _rotation;
    final targetRotation = startRotation + 180;

    // Create animation with expo out curve
    _flipAnimation = Tween<double>(
      begin: startRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutExpo, // Smooth expo out easing
    ))..addListener(() {
      setState(() {
        _rotation = _flipAnimation!.value;
      });
    })..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Normalize rotation to [-180, 180] range after animation completes
        setState(() {
          _rotation = ((_rotation % 360) + 360) % 360;
          if (_rotation > 180) {
            _rotation -= 360;
          }
          
          // Reset velocity so continuous animation eases in smoothly
          _currentVelocity = 0.0;
        });
        
        // Resume continuous animation if it was running
        if (wasAnimating) {
          _startAnimation();
        }
      }
    });

    // Reset and start animation
    controller.reset();
    controller.forward();
  }

  String _formatMedalName(String path) {
    final filename = path.split('/').last;
    return filename
        .replaceAll('.png', '')
        .replaceAll('Badge_conquistas_', '')
        .replaceAll('_', ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF2a2a2a) : const Color(0xFFf5f5f0);
    final cardColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('🏅 3D Medal Library'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Main Medal Display
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  // Medal Name and Controls (Mobile Responsive)
                  Column(
                    children: [
                      Text(
                        _formatMedalName(medalImages[_currentMedalIndex]),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isAnimating ? _stopAnimation : _startAnimation,
                            icon: Icon(_isAnimating ? Icons.pause : Icons.play_arrow),
                            label: Text(_isAnimating ? 'Stop' : 'Animate'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Medal Display
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final size = (constraints.maxWidth - 40).clamp(250.0, 350.0);
                      return Container(
                        width: size,
                        height: size,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : (_frontImage != null &&
                                  _backImage != null &&
                                  _edgePoints != null)
                              ? RepaintBoundary(
                                  child: Medal3D(
                                    frontImage: _frontImage!,
                                    backImage: _backImage!,
                                    edgePoints: _edgePoints!,
                                    rotation: _rotation,
                                    thickness: _thickness,
                                    edgeDarkness: _edgeDarkness,
                                    showEdge: _showEdge,
                                    onTap: _flip,
                                    size: 300,
                                  ),
                                )
                              : const Text('Failed to load medal'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Rotation Control (above library for easy access)
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rotation Angle',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _rotation.clamp(-180.0, 180.0),
                          min: -180,
                          max: 180,
                          divisions: 360,
                          onChanged: (value) {
                            setState(() {
                              _rotation = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${_rotation.round()}°',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Medal Library
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '📚 Medal Library',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '(${medalImages.length} medals)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 120,
                      childAspectRatio: 1,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: medalImages.length,
                    itemBuilder: (context, index) {
                      final isActive = index == _currentMedalIndex;
                      return GestureDetector(
                        onTap: () => _loadMedal(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: isActive
                                ? Border.all(
                                    color: Colors.amber,
                                    width: 3,
                                  )
                                : null,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.amber.withValues(alpha: 0.5),
                                      blurRadius: 15,
                                    ),
                                  ]
                                : null,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            medalImages[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Controls
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Controls',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Thickness
                  _buildSlider(
                    label: 'Medal Thickness',
                    value: _thickness,
                    min: 5,
                    max: 50,
                    divisions: 45,
                    displayValue: '${_thickness.round()}px',
                    onChanged: (value) {
                      setState(() {
                        _thickness = value;
                      });
                    },
                  ),

                  // Edge Darkness
                  _buildSlider(
                    label: 'Edge Darkness',
                    value: _edgeDarkness * 100,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    displayValue: '${(_edgeDarkness * 100).round()}%',
                    onChanged: (value) {
                      setState(() {
                        _edgeDarkness = value / 100;
                      });
                    },
                  ),

                  // Animation Speed
                  _buildSlider(
                    label: 'Animation Speed',
                    value: _animationSpeed,
                    min: 0.5,
                    max: 5,
                    divisions: 45,
                    displayValue: '${_animationSpeed.toStringAsFixed(1)}x',
                    onChanged: (value) {
                      setState(() {
                        _animationSpeed = value;
                      });
                    },
                  ),

                  // Show Edge Toggle
                  SwitchListTile(
                    title: const Text('Show Edge/Extrusion'),
                    value: _showEdge,
                    onChanged: (value) {
                      setState(() {
                        _showEdge = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✨ How to Use',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('• Click thumbnails to switch between medals'),
                        Text('• Tap the medal to flip it 180° with smooth animation'),
                        Text('• Drag sliders to manually rotate and control effects'),
                        Text('• Press Animate button for continuous auto-rotation'),
                        SizedBox(height: 10),
                        Text(
                          'How it works: Uses Flutter CustomPainter with edge detection algorithm that scans the medal image in polar coordinates to create realistic 3D depth effect. Back image is horizontally mirrored so extrusion matches perfectly.',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                displayValue,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

