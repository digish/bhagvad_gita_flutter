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

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:asset_delivery/asset_delivery.dart';
// ADDED for background audio
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/shloka_result.dart';
import '../data/static_data.dart'; // ADDED for chapter titles in MediaItem

// A simple utility to get shloka counts per chapter.
const Map<int, int> _shlokaCounts = {
  1: 47,
  2: 72,
  3: 43,
  4: 42,
  5: 29,
  6: 47,
  7: 30,
  8: 28,
  9: 34,
  10: 42,
  11: 55,
  12: 20,
  13: 35,
  14: 27,
  15: 20,
  16: 24,
  17: 28,
  18: 78,
};

// --- DEVELOPMENT SWITCH ---
const bool _useLocalAssets = false;

// Enum to represent the state of the audio player for a specific shloka
enum PlaybackState { stopped, loading, playing, paused, error }

enum AssetPackStatus {
  unknown,
  notDownloaded,
  pending,
  downloading,
  downloaded,
  failed,
}

// NEW: Shared PlaybackMode enum
enum PlaybackMode { single, continuous, repeatOne }

class AudioProvider extends ChangeNotifier {
  // --- PRIVATE STATE ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingShlokaId;
  PlaybackState _playbackState = PlaybackState.stopped;
  // NEW: Global Playback Mode & Context
  PlaybackMode _playbackMode = PlaybackMode.continuous;
  List<ShlokaResult>? _currentContextShlokas;

  final Map<String, AssetPackStatus> _packStatus = {};
  final Map<String, double> _downloadProgress = {};

  // --- PUBLIC GETTERS ---
  String? get currentPlayingShlokaId => _currentPlayingShlokaId;

  PlaybackState get playbackState => _playbackState;
  PlaybackMode get playbackMode => _playbackMode;
  Duration get position => _audioPlayer.position;

  // --- LIFECYCLE ---
  AudioProvider() {
    // MODIFIED: Call the new async init method that handles everything
    _init();
  }

  // NEW: Combined initialization for asset delivery and background audio
  Future<void> _init() async {
    // 1. Configure the audio session (for background audio)
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    // 2. Initialize asset delivery listeners if required
    if (!_useLocalAssets && !Platform.isIOS) {
      await _initializeAssetDeliveryListeners();
    } else {
      debugPrint(
        "[AUDIO_PROVIDER] Using local/bundled assets. Skipping asset delivery initialization.",
      );
    }

    // 3. Set up player state and error listeners
    _listenToPlayerState();
    _audioPlayer.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace stackTrace) {
        debugPrint('A stream error occurred: $e');
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- PUBLIC METHODS ---

  // NEW: Helper to expose audio path for sharing (Restored)
  Future<String?> getShlokaAudioPath(ShlokaResult shloka) {
    return _getShlokaAssetPath(shloka);
  }

  // Restored: Check download status for a chapter
  AssetPackStatus getChapterPackStatus(int chapterNumber) {
    // MODIFIED: On iOS or when using local assets, we treat everything as downloaded.
    if (_useLocalAssets || Platform.isIOS) {
      return AssetPackStatus.downloaded;
    }
    final packName = _getPackName(chapterNumber);
    return _packStatus[packName] ?? AssetPackStatus.unknown;
  }

  // Restored: Get download progress
  double getChapterDownloadProgress(int chapterNumber) {
    final packName = _getPackName(chapterNumber);
    return _downloadProgress[packName] ?? 0.0;
  }

  // --- PUBLIC METHODS ---

  // NEW: Expose current index stream for UI sync
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;

  // NEW: Expose sequence state stream to detect playlist changes
  Stream<SequenceState?> get sequenceStateStream =>
      _audioPlayer.sequenceStateStream;

  // NEW: Expose position stream for progress bar
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  // NEW: Expose duration stream for progress bar
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  // NEW: Seek method
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // NEW: Simple toggle for the current item (Mini Player)
  Future<void> togglePlayback() async {
    if (_playbackState == PlaybackState.playing) {
      await _audioPlayer.pause();
    } else if (_playbackState == PlaybackState.paused) {
      await _audioPlayer.play();
    }
  }

  // NEW: Cycle Playback Mode (Global)
  Future<void> cyclePlaybackMode() async {
    final nextIndex = (_playbackMode.index + 1) % PlaybackMode.values.length;
    _playbackMode = PlaybackMode.values[nextIndex];
    notifyListeners();

    // If currently playing or paused, re-apply the mode by reloading
    if ((_playbackState == PlaybackState.playing ||
            _playbackState == PlaybackState.paused) &&
        _currentContextShlokas != null &&
        _currentPlayingShlokaId != null) {
      final currentIndex = _currentContextShlokas!.indexWhere(
        (s) => '${s.chapterNo}.${s.shlokNo}' == _currentPlayingShlokaId,
      );

      if (currentIndex != -1) {
        // Reload playback with new mode, preserving position
        await playChapter(
          shlokas: _currentContextShlokas!,
          initialIndex: currentIndex,
          initialPosition: position,
          // Force existing mode to be used
        );
      }
    }
  }

  // NEW: Public stop method (Mini Player)
  Future<void> stopPlayback() async {
    await _stop(_currentPlayingShlokaId);
  }

  // NEW: Combined Play Function that handles both Single and Playlist modes
  // based on the context.
  Future<void> playChapter({
    required List<ShlokaResult> shlokas,
    required int initialIndex,
    // playbackMode is now internal, optional override for specific cases?
    // Removing argument to enforce global state consistency.
    Duration? initialPosition,
  }) async {
    // Cache the context for mode switching
    _currentContextShlokas = shlokas;
    final shloka = shlokas[initialIndex];
    final shlokaId = '${shloka.chapterNo}.${shloka.shlokNo}';

    // 0. Set Loop Mode based on PlaybackMode
    switch (_playbackMode) {
      case PlaybackMode.single:
        await _audioPlayer.setLoopMode(LoopMode.off);
        break;
      case PlaybackMode.continuous:
        await _audioPlayer.setLoopMode(
          LoopMode.off,
        ); // Playlist logic handles sequence
        break;
      case PlaybackMode.repeatOne:
        await _audioPlayer.setLoopMode(LoopMode.one);
        break;
    }

    // 1. Handle Play/Pause Toggle if tapping the same shloka
    // Skip this check if initialPosition is provided (implies reloading config/mode)
    if (_currentPlayingShlokaId == shlokaId && initialPosition == null) {
      if (_playbackState == PlaybackState.playing) {
        await _audioPlayer.pause();
        return;
      } else if (_playbackState == PlaybackState.paused) {
        await _audioPlayer.play();
        return;
      }
    }

    // 2. Stop previous playback nicely
    await _stop(_currentPlayingShlokaId, notify: false);
    _currentPlayingShlokaId = shlokaId;
    _setPlaybackState(PlaybackState.loading);

    try {
      if (_playbackMode == PlaybackMode.continuous) {
        // --- CONTINUOUS MODE (Playlist) ---
        // Optimization: Get base path once for Android
        String? chapterPackPath;
        final chapterNum = int.parse(shlokas.first.chapterNo);
        if (!_useLocalAssets && !Platform.isIOS) {
          chapterPackPath = await _getShlokaAssetPathForChapter(chapterNum);
        }

        final List<AudioSource> sources = [];

        for (var s in shlokas) {
          Uri? uri;
          if (_useLocalAssets || Platform.isIOS) {
            final path = await _getShlokaAssetPath(s); // Uses bundle logic
            if (path != null) uri = Uri.parse('asset:///$path');
          } else {
            // Android Optimization: Build path manually from base
            if (chapterPackPath != null) {
              final sNum = int.parse(s.shlokNo).toString().padLeft(2, '0');
              final cNum = chapterNum.toString().padLeft(2, '0');
              final finalPath = '$chapterPackPath/ch${cNum}_sh$sNum.opus';
              uri = Uri.file(finalPath);
            }
          }

          if (uri != null) {
            sources.add(
              AudioSource.uri(
                uri,
                tag: MediaItem(
                  id: '${s.chapterNo}.${s.shlokNo}',
                  album:
                      "Chapter ${s.chapterNo}: ${StaticData.geetaAdhyay[int.parse(s.chapterNo) - 1]}",
                  title: "Shloka ${s.chapterNo}.${s.shlokNo}",
                  artist: s.speaker ?? "Gita Recitation",
                ),
              ),
            );
          } else {
            // If a file is missing, we might have to skip it or add a silence placeholder?
            // For now, we just don't add it, which might shift indices.
            // Ideally we should handle this, but for now assuming download is complete.
          }
        }

        final playlist = ConcatenatingAudioSource(children: sources);
        await _audioPlayer.setAudioSource(
          playlist,
          initialIndex: initialIndex,
          initialPosition: initialPosition,
        );
        await _audioPlayer.play();
      } else {
        // --- SINGLE / REPEAT ONE MODE ---
        // Use existing logic for single source
        final assetPath = await _getShlokaAssetPath(shloka);
        if (assetPath == null) {
          _setPlaybackState(PlaybackState.error);
          return;
        }

        final mediaItem = MediaItem(
          id: shlokaId,
          album:
              "Chapter ${shloka.chapterNo}: ${StaticData.geetaAdhyay[int.parse(shloka.chapterNo) - 1]}",
          title: "Shloka ${shloka.chapterNo}.${shloka.shlokNo}",
          artist: shloka.speaker ?? "Gita Recitation",
        );

        final uri = (_useLocalAssets || Platform.isIOS)
            ? Uri.parse('asset:///$assetPath')
            : Uri.file(assetPath);

        await _audioPlayer.setAudioSource(
          AudioSource.uri(uri, tag: mediaItem),
          initialPosition: initialPosition,
        );
        await _audioPlayer.play();
      }
    } catch (e) {
      if (e.toString().contains('Loading interrupted')) return;
      debugPrint("Error playing audio: $e");
      _setPlaybackState(PlaybackState.error);
    }
  }

  // Deprecated wrapper for backward compatibility if needed, or just remove it.
  Future<void> playOrPauseShloka(ShlokaResult shloka) async {
    // This assumes single mode.
    playChapter(shlokas: [shloka], initialIndex: 0);
  }

  Future<void> initiateChapterAudioDownload(int chapterNumber) async {
    if (_useLocalAssets || Platform.isIOS) return;
    final packName = _getPackName(chapterNumber);
    final currentStatus = getChapterPackStatus(chapterNumber);

    debugPrint(
      "[ASSET_DELIVERY] User initiated download for chapter $chapterNumber (pack: $packName). Current status: $currentStatus",
    );

    // Don't re-initiate if already pending or downloading
    if (currentStatus == AssetPackStatus.downloading ||
        currentStatus == AssetPackStatus.pending) {
      debugPrint(
        "[ASSET_DELIVERY] Download for $packName is already in progress. Ignoring request.",
      );
      return;
    }

    // Set status to pending immediately for instant UI feedback
    _packStatus[packName] = AssetPackStatus.pending;
    notifyListeners();
    debugPrint(
      "[ASSET_DELIVERY] Set $packName status to PENDING for UI feedback.",
    );

    try {
      // Use fetch() to initiate the download, as per the plugin example.
      // This is a "fire-and-forget" call. The listener will handle status updates.
      await AssetDelivery.fetch(packName);
    } catch (e, s) {
      debugPrint(
        "[ASSET_DELIVERY] CRITICAL ERROR initiating download for chapter $chapterNumber: $e",
      );
      debugPrint("[ASSET_DELIVERY] Stack trace: $s");
      _packStatus[packName] = AssetPackStatus.failed;
      notifyListeners();
    }
  }

  // --- PRIVATE HELPERS ---
  // RENAMED for clarity
  Future<void> _initializeAssetDeliveryListeners() async {
    debugPrint("[ASSET_DELIVERY] Initializing asset delivery listeners...");
    // On startup, we don't know the status of on-demand packs.
    final packNames = List.generate(18, (i) => _getPackName(i + 1));
    for (final packName in packNames) {
      // Initialize all to unknown first.
      _packStatus[packName] = AssetPackStatus.unknown;
    }

    // Now, query the actual status of all packs.
    // We must check each one individually.
    for (var i = 0; i < 18; i++) {
      final chapter = i + 1;
      final packName = _getPackName(chapter);
      try {
        // Try to get the path. If it succeeds, the pack is downloaded.
        final path = await _getShlokaAssetPathForChapter(chapter);
        _packStatus[packName] = (path != null)
            ? AssetPackStatus.downloaded
            : AssetPackStatus.notDownloaded;
      } catch (e) {
        // This is expected if the pack is not downloaded.
        _packStatus[packName] = AssetPackStatus.notDownloaded;
      }
    }
    debugPrint("[ASSET_DELIVERY] Initial pack statuses loaded: $_packStatus");

    // This listener will inform us of the status of any active or future downloads.
    debugPrint("[ASSET_DELIVERY] Registering for asset pack status updates.");
    AssetDelivery.getAssetPackStatus(_updateStatusFromMap);
  }

  // NEW: Extracted the status update logic into a reusable helper method.
  void _applyStatusUpdate(
    String packName,
    String? statusString,
    double? progress,
  ) {
    switch (statusString) {
      case 'PENDING':
        _packStatus[packName] = AssetPackStatus.pending;
        break;
      case 'DOWNLOADING':
      case 'TRANSFERRING':
      case 'WAITING_FOR_WIFI':
        _packStatus[packName] = AssetPackStatus.downloading;
        if (progress != null) _downloadProgress[packName] = progress;
        break;
      case 'COMPLETED':
        _packStatus[packName] = AssetPackStatus.downloaded;
        _downloadProgress.remove(packName);
        break;
      case 'FAILED':
      case 'CANCELED':
        _packStatus[packName] = AssetPackStatus.failed;
        _downloadProgress.remove(packName);
        break;
    }
    notifyListeners();
  }

  void _updateStatusFromMap(Map<dynamic, dynamic> statusMap) {
    final packName = statusMap['assetPackName'] as String?;
    final statusString = statusMap['status'] as String?;
    final progress = statusMap['downloadProgress'] as double?;

    debugPrint("[ASSET_DELIVERY_LISTENER] Received status update: $statusMap");

    if (packName != null) {
      _applyStatusUpdate(packName, statusString, progress);
      return;
    }

    // WORKAROUND: The plugin sometimes sends status updates without a pack name.
    // If this happens, we'll find the pack that is currently in a transient state
    // (pending or downloading) and apply the update to it. This assumes only
    // one download happens at a time, which is true for the current UI.
    debugPrint(
      "[ASSET_DELIVERY_LISTENER] Received status update with null packName. Applying workaround...",
    );
    String? activeDownloadPackName;
    try {
      activeDownloadPackName = _packStatus.entries
          .firstWhere(
            (entry) =>
                entry.value == AssetPackStatus.pending ||
                entry.value == AssetPackStatus.downloading,
          )
          .key;
    } on StateError {
      // This is expected if no download is active.
      activeDownloadPackName = null;
    }

    if (activeDownloadPackName != null) {
      debugPrint(
        "[ASSET_DELIVERY_LISTENER] Workaround: Found active pack '$activeDownloadPackName'. Applying status update.",
      );
      _applyStatusUpdate(activeDownloadPackName, statusString, progress);
    } else {
      debugPrint(
        "[ASSET_DELIVERY_LISTENER] Workaround failed: Could not find an active download to apply the status to.",
      );
    }
  }

  void _listenToPlayerState() {
    _audioPlayer.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      switch (state.processingState) {
        case ProcessingState.idle:
          break;
        case ProcessingState.completed:
          _stop(_currentPlayingShlokaId);
          break;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          _setPlaybackState(PlaybackState.loading);
          break;
        case ProcessingState.ready:
          _setPlaybackState(
            isPlaying ? PlaybackState.playing : PlaybackState.paused,
          );
          break;
      }
    });

    // NEW: Listen to current index to update the current playing ID
    // This is crucial for the UI to know what is playing when auto-advancing
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null &&
          _audioPlayer.audioSource is ConcatenatingAudioSource) {
        final playlist = _audioPlayer.audioSource as ConcatenatingAudioSource;
        if (index < playlist.length) {
          final source = playlist.children[index] as UriAudioSource;
          // We attached MediaItem as tag.
          if (source.tag is MediaItem) {
            final mediaItem = source.tag as MediaItem;
            if (_currentPlayingShlokaId != mediaItem.id) {
              _currentPlayingShlokaId = mediaItem.id;
              notifyListeners();
            }
          }
        }
      }
    });
  }

  Future<void> _stop(String? completedShlokaId, {bool notify = true}) async {
    // If the current playing ID is different from the one that just completed,
    // it means a new shloka has already been requested (e.g., by continuous play).
    // In this case, we should not stop the playback process.
    if (_currentPlayingShlokaId != completedShlokaId) {
      debugPrint(
        "[AUDIO_PROVIDER] Stop called for $completedShlokaId, but new shloka $_currentPlayingShlokaId is already loading. Aborting stop.",
      );
      return;
    }

    await _audioPlayer.stop();
    // Only nullify if we are truly stopping the shloka that just finished.
    _setPlaybackState(PlaybackState.stopped, notify: notify);
  }

  void _setPlaybackState(PlaybackState state, {bool notify = true}) {
    if (_playbackState != state) {
      debugPrint(
        "[AUDIO_PROVIDER] State changing from $_playbackState to $state for ID $_currentPlayingShlokaId",
      );
      _playbackState = state;

      // Toggle Wakelock based on state
      if (state == PlaybackState.playing) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }

      if (notify) notifyListeners();
    }
  }

  // A new helper to get the asset path for an entire chapter, used for downloads.
  Future<String?> _getShlokaAssetPathForChapter(int chapter) async {
    if (_useLocalAssets) return null;

    final packName = _getPackName(chapter);
    final chapterPadded = chapter.toString().padLeft(2, '0');

    // This call is now only used to get the path of an already available pack.
    // The `count` and `namingPattern` are ignored on Android but required by the method signature.
    try {
      final assetPackPath = await AssetDelivery.getAssetPackPath(
        // These parameters are ignored on Android but are essential for iOS.
        // Providing the correct values now makes the code future-proof.
        assetPackName: packName,
        count: _shlokaCounts[chapter] ?? 0,
        // The '%02d' format tells iOS to generate zero-padded numbers (01, 02, etc.),
        // matching your file names.
        namingPattern: 'ch${chapterPadded}_sh%02d',
        fileExtension: 'opus',
      );
      debugPrint(
        "[ASSET_DELIVERY] Successfully got asset pack path for $packName: $assetPackPath",
      );
      if (assetPackPath == null) {
        throw Exception(
          'AssetDelivery.getAssetPackPath returned null. The pack is not available on the device.',
        );
      }
      return assetPackPath;
    } catch (e, s) {
      // This is an expected failure if the pack is not on the device.
      debugPrint(
        "[ASSET_DELIVERY] Could not get asset pack path for $packName (likely not downloaded). Error: $e",
      );
      return null;
    }
  }

  String _getPackName(int chapterNumber) => 'Chapter${chapterNumber}_audio';

  Future<String?> _getShlokaAssetPath(ShlokaResult shloka) async {
    try {
      final chapter = int.parse(shloka.chapterNo);
      final shlokNum = int.parse(shloka.shlokNo);
      final packName = _getPackName(chapter);
      final chapterPadded = chapter.toString().padLeft(2, '0');
      // Use the original, preferred naming scheme: 1-based and zero-padded.
      final shlokPadded = shlokNum.toString().padLeft(2, '0');

      // MODIFIED: Use bundled assets for iOS or if _useLocalAssets is true
      // Since we removed local .opus files, we must use .m4a for all local/bundled usage.
      if (_useLocalAssets || Platform.isIOS) {
        return 'assets/audio/$packName/ch${chapterPadded}_sh$shlokPadded.m4a';
      } else {
        // Use the new helper to get the base path for the chapter.
        final assetPackPath = await _getShlokaAssetPathForChapter(chapter);
        if (assetPackPath == null) {
          debugPrint(
            "[ASSET_DELIVERY] Base asset pack path for chapter $chapter is null. Cannot construct shloka path.",
          );
          return null;
        }
        // IMPORTANT: The filename here must exactly match the file in your asset pack's assets folder.
        final finalPath =
            '$assetPackPath/ch${chapterPadded}_sh$shlokPadded.opus';
        debugPrint(
          "[ASSET_DELIVERY] Constructed final path for playback: $finalPath",
        );
        return finalPath;
      }
    } catch (e) {
      debugPrint("[ASSET_DELIVERY] CRITICAL ERROR in _getShlokaAssetPath: $e");
      return null;
    }
  }
}
