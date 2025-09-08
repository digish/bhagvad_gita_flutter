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
import 'package:go_router/go_router.dart';
import '../../models/word_result.dart';
import 'dart:ui';

class WordResultCard extends StatelessWidget {
  final WordResult word;

  const WordResultCard({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1), // frosted background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.amberAccent.withOpacity(0.5), // golden border
                width: 1.0,
              ),
            ),
            child: InkWell(
              onTap: () {
                context.push('/shloka-list/${Uri.encodeComponent(word.word)}');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.definition,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.blueGrey.shade100,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
