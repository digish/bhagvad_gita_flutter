/* 
*  © 2025 Digish Pandya. All rights reserved.
*
*  This mobile application, "Shrimad Bhagavad Gita," including its code, design, and original content, is released under the [MIT License] unless otherwise noted.
*
*  The sacred text of the Bhagavad Gita, as presented herein, is in the public domain. Translations, interpretations, UI elements, and artistic representations created by the developer are protected under copyright law.
*
*  This app is offered in the spirit of dharma and shared learning. You are welcome to use, modify, and distribute the source code under the terms of the MIT License. However, please preserve the integrity of the spiritual message and credit the original contributors where due.
*
*  For licensing details, see the LICENSE file in the repository.
*
**/

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
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Always repaint as time is always changing
    return true;
  }
}

class WaterRippleBackground extends StatefulWidget {
  const WaterRippleBackground({super.key});

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
    _shaderProgramFuture = ui.FragmentProgram.fromAsset(
      'assets/shaders/ripple.frag',
    );
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 100,
      ), // A long duration for continuous animation
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
              // Vital stability fix: ClipRect prevents the custom shader from rendering
              // to 'infinity', which crashes the iOS Simulator's Metal driver (MTLSimDriver).
              return ClipRect(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.6)
                        : Colors.transparent,
                    BlendMode.darken,
                  ),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _ShaderPainter(
                      shader: snapshot.data!,
                      time:
                          _timeController.value *
                          _timeController.duration!.inMilliseconds /
                          1000.0,
                      resolution: MediaQuery.of(context).size,
                    ),
                  ),
                ),
              );
            },
          );
        }
        // ✨ FIX: Return a solid color instead of a loader to prevent "White Flash"
        // This matches the ripple's base color so the transition is seamless.
        return Container(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
        );
      },
    );
  }
}
