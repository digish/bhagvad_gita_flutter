import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// A CustomPainter to render the shader
class _ShaderPainter extends CustomPainter {
  final ui.FragmentProgram shader;
  final double time;
  final Size resolution;

  _ShaderPainter({
    required this.shader,
    required this.time,
    required this.resolution,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = this.shader.fragmentShader();

    // Set the only necessary uniforms: time and resolution
    shader.setFloat(0, time);
    shader.setFloat(1, resolution.width);
    shader.setFloat(2, resolution.height);

    // Draw the shader
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Always repaint as time is always changing
    return true;
  }
}

class WaterRippleBackground extends StatefulWidget {
  const WaterRippleBackground({
    super.key,
  });

  @override
  State<WaterRippleBackground> createState() => _WaterRippleBackgroundState();
}

class _WaterRippleBackgroundState extends State<WaterRippleBackground>
    with SingleTickerProviderStateMixin {
  late final Future<ui.FragmentProgram> _shaderProgramFuture;
  late final AnimationController _timeController;

  @override
  void initState() {
    super.initState();
    // Load the shader from the asset file
    _shaderProgramFuture =
        ui.FragmentProgram.fromAsset('assets/shaders/ripple.frag');
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 100), // A long duration for continuous animation
    )..repeat();
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.FragmentProgram>(
      future: _shaderProgramFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading shader: ${snapshot.error}'));
        }
        if (snapshot.hasData) {
          return AnimatedBuilder(
            animation: _timeController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ShaderPainter(
                  shader: snapshot.data!,
                  time: _timeController.value *
                      _timeController.duration!.inMilliseconds /
                      1000.0,
                  resolution: MediaQuery.of(context).size,
                ),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

