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
