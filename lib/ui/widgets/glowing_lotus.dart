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
