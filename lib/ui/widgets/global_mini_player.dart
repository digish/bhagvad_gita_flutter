import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';

class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final playbackState = audioProvider.playbackState;
        final currentId = audioProvider.currentPlayingShlokaId;

        // Hide if stopped or no track is identified
        if (playbackState == PlaybackState.stopped || currentId == null) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            // Only round top corners for a "Docked" look
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: double.infinity,
                // Use a decoration that extends to the bottom
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withOpacity(
                    0.85,
                  ),
                  border: Border(
                    top: BorderSide(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.1,
                      ),
                      width: 0.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✨ Innovative Touch: A subtle gradient progress glow at the top
                    StreamBuilder<Duration>(
                      stream: audioProvider
                          .positionStream, // We need to expose this
                      builder: (context, snapshot) {
                        // Just trigger rebuilds for now, progress bar logic to be added later if needed
                        return Container(
                          height: 2,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.3),
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0.3),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SafeArea(
                      top: false,
                      // Maintain bottom safe area padding so controls don't overlap home indicator
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            // 1. Album Art / Emblem
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                image: const DecorationImage(
                                  // Placeholder or generic emblem.
                                  // Using Gold Lotus for premium feel
                                  image: AssetImage(
                                    'assets/images/lotus_gold.png',
                                  ),
                                  fit: BoxFit.contain,
                                  opacity: 0.8,
                                ),
                              ),
                              // Fallback if image not found/loading
                              child: const Icon(
                                Icons.music_note_rounded,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // 2. Info (Title & Subtitle)
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatTitle(currentId),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    playbackState == PlaybackState.loading
                                        ? "Loading..."
                                        : "Now Playing",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // 3. Playback Controls
                            IconButton(
                              onPressed: audioProvider.togglePlayback,
                              icon: Icon(
                                playbackState == PlaybackState.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 36,
                                color: theme.colorScheme.primary,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: audioProvider.stopPlayback,
                              icon: Icon(
                                Icons.close_rounded,
                                size: 24,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTitle(String currentId) {
    // Current ID is "Chapter.Shloka" wrapper
    return "Verse $currentId";
  }
}
