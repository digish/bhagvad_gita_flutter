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
import 'dart:math';
import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'dart:ui';

class Lotus extends StatefulWidget {
  const Lotus({super.key});

  @override
  State<Lotus> createState() => _LotusState();
}

class _LotusState extends State<Lotus> with TickerProviderStateMixin {
  late Ticker _ticker;
  late double rotationAngle;
  late double rotationSpeed;
  late double rotationDirection;
  late Timer _timer;

  late AnimationController _glowController;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    final random = Random();

    rotationAngle = 0.0;
    rotationDirection = random.nextBool() ? 1.0 : -1.0;
    rotationSpeed = _generateRandomSpeed();

    _ticker = createTicker((elapsed) {
      setState(() {
        rotationAngle += rotationDirection * rotationSpeed;
      });
    });

    _ticker.start();

    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      rotationSpeed = _generateRandomSpeed();
    });

    // Pulse glow setup
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowOpacity = Tween<double>(begin: 0.4, end: 0.75).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  double _generateRandomSpeed() {
    final random = Random();
    return 0.0005 + random.nextDouble() * 0.001; // very slow
  }

  @override
  void dispose() {
    _ticker.dispose();
    _timer.cancel();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide > 600;
    final isSmallPhone = size.width < 380;

    final double glowSize = isTablet
        ? 400
        : isSmallPhone
        ? 200
        : 250;
    final double imageSize = isTablet
        ? 360
        : isSmallPhone
        ? 180
        : 230;

    return Transform.rotate(
      angle: rotationAngle,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated pulse glow
          AnimatedBuilder(
            animation: _glowOpacity,
            builder: (context, child) => Opacity(
              opacity: _glowOpacity.value,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  const Color.fromARGB(255, 255, 255, 255),
                  BlendMode.srcATop,
                ),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Image.asset(
                    'assets/images/lotus_top.png',
                    width: glowSize,
                    height: glowSize,
                  ),
                ),
              ),
            ),
          ),

          // Crisp lotus image
          Image.asset(
            'assets/images/lotus_top.png',
            width: imageSize,
            height: imageSize,
          ),
        ],
      ),
    );
  }
}
