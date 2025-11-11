# 3D Medal Rotation Proof of Concept

## Overview
This proof of concept demonstrates a technique for faking 3D rotation of medal images with irregular edges. The solution extracts the outline of each medal and dynamically generates an edge/extrusion effect during rotation.

## Key Features
- **Irregular Edge Detection**: Automatically detects the outline of medals with non-circular shapes
- **Dynamic Edge Rendering**: Creates a side edge that follows the irregular shape during rotation
- **Natural Rotation Direction**: Front disappears on the right, back appears on the left
- **Dual-Sided Medals**: Automatic silver/desaturated back side for realistic coin effect
- **Interactive Controls**: Adjust rotation, thickness, darkness, and animation speed in real-time
- **Debug Mode**: Toggle outline visualization to see the detected edge points

## Technique Explanation

### The Problem
Simply scaling the X-axis from 1 to 0 to -1 doesn't work well for irregular shapes because:
1. The medal appears to "shrink" rather than "rotate"
2. No depth/thickness is visible
3. Irregular edges don't look natural during the transition

### The Solution
1. **Edge Detection**: Scan the medal image in polar coordinates from the center, detecting where the alpha channel indicates the edge
2. **Edge Extrusion**: When the medal rotates (scaleX approaches 0), create a continuous edge shape by connecting the front outline to an offset outline, creating a solid 3D thickness
3. **Directional Rendering**: Edge extends to the right during clockwise rotation, to the left during counter-clockwise rotation
4. **Dual-Sided Images**: Automatically generate a desaturated silver version for the back of the medal
5. **Gradient Shading**: Apply metallic gradients across the edge for depth and lighting effects

## How to Run

1. Open Terminal and navigate to this directory:
   ```bash
   cd "/Users/matheusaugustoalecrimdesousacorrea/Documents/3d medals"
   ```

2. Start a local web server (choose one):
   
   **Python 3:**
   ```bash
   python3 -m http.server 8000
   ```
   
   **Python 2:**
   ```bash
   python -m SimpleHTTPServer 8000
   ```
   
   **Node.js (if installed):**
   ```bash
   npx http-server -p 8000
   ```

3. Open your browser and go to:
   ```
   http://localhost:8000
   ```

## Controls

- **Rotation Angle**: Manually control the rotation angle (-180° to 180°)
- **Edge Thickness**: Adjust how thick the medal's side edge appears (1-50px)
- **Edge Darkness**: Control how dark the edge appears (0-100%)
- **Animation Speed**: Set the speed of automatic rotation (0.5x - 5x)
- **Show Edge/Extrusion**: Toggle the edge rendering on/off
- **Show Debug Outline**: Display the detected outline in green
- **Animate Rotation**: Start automatic rotation
- **Stop**: Pause the animation
- **Reset**: Return to 0° rotation

## Porting to Flutter

Key concepts to implement in Flutter:

1. **CustomPainter** for rendering
2. **Transform.scale()** for X-axis scaling
3. **Path** for irregular edge shapes
4. **Canvas.drawPath()** for edge rendering
5. **AnimationController** for smooth transitions

The core algorithm can be ported using:
- Image package to analyze pixels
- CustomPaint widget for rendering
- Transform widget for scaling

## Tips for Best Results

- **Edge Thickness**: 10-20px works well for most medals
- **Edge Darkness**: 60-80% provides good contrast
- **Animation Speed**: 1.5-2.5x gives smooth, visible rotation
- Use the debug outline to understand how the edge detection works

## Next Steps

1. Test with different medal designs
2. Fine-tune edge detection algorithm if needed
3. Add lighting effects for more realism
4. Implement in Flutter using similar techniques

