import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';


class GlowingLotus extends StatefulWidget {
  const GlowingLotus({super.key});

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
            width: 256,
            height: 256,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Blurred glow layer
                Opacity(
                  opacity: _glowAnimation.value,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: 3.0,
                      sigmaY: 3.0,
                    ),
                    child: SvgPicture.asset(
                      'assets/images/lotus_art.svg',
                      color: Colors.amberAccent,
                    ),
                  ),
                ),
                // Crisp line layer
                SvgPicture.asset(
                  'assets/images/lotus_art.svg',
                  color: Colors.amberAccent.withOpacity(0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
