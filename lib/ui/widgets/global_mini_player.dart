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
                    const SizedBox(
                      height: 6,
                    ), // Add breathing room above seekbar
                    // Progress Bar / Seekbar
                    _MiniPlayerSeekbar(audioProvider: audioProvider),
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
                            // Playback Mode Toggle
                            IconButton(
                              onPressed: audioProvider.cyclePlaybackMode,
                              icon: Icon(
                                _getPlaybackModeIcon(
                                  audioProvider.playbackMode,
                                ),
                                size: 24,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: _getPlaybackModeTooltip(
                                audioProvider.playbackMode,
                              ),
                            ),
                            const SizedBox(width: 16),
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

  IconData _getPlaybackModeIcon(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.single:
        return Icons.looks_one_rounded; // '1' icon to indicate single play
      case PlaybackMode.continuous:
        return Icons.playlist_play;
      case PlaybackMode.repeatOne:
        return Icons.repeat_one;
    }
  }

  String _getPlaybackModeTooltip(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.single:
        return 'Single Verse';
      case PlaybackMode.continuous:
        return 'Continuous Play';
      case PlaybackMode.repeatOne:
        return 'Repeat One';
    }
  }
}

class _MiniPlayerSeekbar extends StatefulWidget {
  final AudioProvider audioProvider;
  const _MiniPlayerSeekbar({required this.audioProvider});

  @override
  State<_MiniPlayerSeekbar> createState() => _MiniPlayerSeekbarState();
}

class _MiniPlayerSeekbarState extends State<_MiniPlayerSeekbar> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<Duration?>(
      stream: widget.audioProvider.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: widget.audioProvider.positionStream,
          builder: (context, positionSnapshot) {
            var position = positionSnapshot.data ?? Duration.zero;
            if (position > duration) {
              position = duration;
            }

            // Use drag value if dragging, otherwise stream value
            final currentValue = _isDragging
                ? _dragValue
                : position.inMilliseconds.toDouble();
            final maxValue = duration.inMilliseconds.toDouble();

            // Safety check to ensure value doesn't exceed max
            final effectiveValue = currentValue.clamp(0.0, maxValue);

            return Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.0,
                  trackShape: const RoundedRectSliderTrackShape(),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8.0,
                    elevation: 4,
                    pressedElevation: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24.0,
                  ),
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor: theme.colorScheme.primary.withOpacity(
                    0.15,
                  ),
                  thumbColor: theme.colorScheme.secondary,
                  overlayColor: theme.colorScheme.secondary.withOpacity(0.2),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Slider(
                    value: effectiveValue,
                    min: 0.0,
                    max: maxValue,
                    onChangeStart: (value) {
                      setState(() {
                        _isDragging = true;
                        _dragValue = value;
                      });
                    },
                    onChanged: (value) {
                      setState(() {
                        _dragValue = value;
                      });
                    },
                    onChangeEnd: (value) {
                      setState(() {
                        _isDragging = false;
                        _dragValue = value;
                      });
                      widget.audioProvider.seek(
                        Duration(milliseconds: value.toInt()),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
