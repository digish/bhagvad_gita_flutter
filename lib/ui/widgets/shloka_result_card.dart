import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/shloka_result.dart';
import '../../navigation/app_router.dart';
import 'dart:ui';

class ShlokaResultCard extends StatelessWidget {
  final ShlokaResult shloka;

  const ShlokaResultCard({super.key, required this.shloka});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final displayShlok = shloka.shlok
        .replaceAll(RegExp(r'<c>', caseSensitive: false), '')
        .replaceAll('*', ' ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: const Color(0xFFFFD700), // Golden border
                width: 1.2,
              ),
            ),
            child: InkWell(
              onTap: () {
                context.push(AppRoutes.shlokaDetail.replaceFirst(':id', shloka.id.toString()));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chapter ${shloka.chapterNo}, Shloka ${shloka.shlokNo}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFD700), // Golden accent
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayShlok,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.85),
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
