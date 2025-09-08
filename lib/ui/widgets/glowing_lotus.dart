import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';

class GlowingLotus extends StatefulWidget {
  final double width;
  final double height;
  final double sigma;

  const GlowingLotus({
    super.key,
    this.width = 256,
    this.height = 256,
    this.sigma = 3.0,
  });

  @override
  State<GlowingLotus> createState() => _GlowingLotusState();
}

class _GlowingLotusState extends State<GlowingLotus>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Center(
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Blurred glow layer
                Opacity(
                  opacity: _glowAnimation.value,
                  child: ImageFiltered(
                    imageFilter:
                        ImageFilter.blur(sigmaX: widget.sigma, sigmaY: widget.sigma),
                    child: SvgPicture.asset(
                      'assets/images/lotus_art.svg',
                      colorFilter: const ColorFilter.mode(
                          Color.fromARGB(255, 255, 64, 210), BlendMode.srcIn),
                    ),
                  ),
                ),
                // Crisp line layer
                SvgPicture.asset(
                  'assets/images/lotus_art.svg',
                  colorFilter: ColorFilter.mode(
                      const Color.fromARGB(255, 164, 6, 138).withOpacity(0.9), BlendMode.srcIn),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
