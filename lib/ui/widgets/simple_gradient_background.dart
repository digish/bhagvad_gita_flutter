import 'package:flutter/material.dart';
import 'dart:ui';
import './glowing_lotus.dart';


class SimpleGradientBackground extends StatefulWidget {
  const SimpleGradientBackground({super.key});

  @override
  State<SimpleGradientBackground> createState() =>
      _SimpleGradientBackgroundState();
}

class _SimpleGradientBackgroundState extends State<SimpleGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.white,
            ),
            // Use the reusable GlowingLotus widget
            const GlowingLotus(
              width: 300,
              height: 300,
              sigma: 5.0,
            ),
            // The bottom leaves image
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: MediaQuery.of(context).size.height,
                height: MediaQuery.of(context).size.width,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Golden glow layer
                    Opacity(
                      opacity: 0.5,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          const Color.fromARGB(255, 0, 0, 0),
                          BlendMode.srcATop,
                        ),
                        child: ImageFiltered(
                          imageFilter:
                              ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                          child: Transform.rotate(
                            angle: 270 * 3.1415926535 / 180,
                            child: Image.asset(
                              'assets/images/leaves_background.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Crisp leaves image
                    Transform.rotate(
                      angle: 270 * 3.1415926535 / 180,
                      child: Image.asset(
                        'assets/images/leaves_background.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
      },
    );
  }
}