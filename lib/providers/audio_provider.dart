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
import '../models/shloka_result.dart';
import '../data/static_data.dart'; // ADDED for chapter titles in MediaItem

// A simple utility to get shloka counts per chapter.
const Map<int, int> _shlokaCounts = {
  1: 47, 2: 72, 3: 43, 4: 42, 5: 29, 6: 47, 7: 30, 8: 28, 9: 34,
  10: 42, 11: 55, 12: 20, 13: 35, 14: 27, 15: 20, 16: 24, 17: 28, 18: 78
};

// --- DEVELOPMENT SWITCH ---
const bool _useLocalAssets = false;


// Enum to represent the state of the audio player for a specific shloka
enum PlaybackState { stopped, loading, playing, paused, error }

// Enum to represent the download status of a chapter's audio asset pack
enum AssetPackStatus {
  unknown,
  notDownloaded,
  pending,
  downloading,
  downloaded,
  failed
}

class AudioProvider extends ChangeNotifier {
  // --- PRIVATE STATE ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingShlokaId;
  PlaybackState _playbackState = PlaybackState.stopped;

  final Map<String, AssetPackStatus> _packStatus = {};
  final Map<String, double> _downloadProgress = {};

  // --- PUBLIC GETTERS ---
  String? get currentPlayingShlokaId => _currentPlayingShlokaId;
  PlaybackState get playbackState => _playbackState;

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
    } else { debugPrint("[AUDIO_PROVIDER] Using local/bundled assets. Skipping asset delivery initialization."); }
    
    // 3. Set up player state and error listeners
    _listenToPlayerState();
    _audioPlayer.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      debugPrint('A stream error occurred: $e');
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- PUBLIC METHODS ---

  AssetPackStatus getChapterPackStatus(int chapterNumber) {
    final packName = _getPackName(chapterNumber);
    return _packStatus[packName] ?? AssetPackStatus.unknown;
  }

  double getChapterDownloadProgress(int chapterNumber) {
    final packName = _getPackName(chapterNumber);
    return _downloadProgress[packName] ?? 0.0;
  }

  Future<void> playOrPauseShloka(ShlokaResult shloka) async {
    final shlokaId = '${shloka.chapterNo}.${shloka.shlokNo}';
    final isCurrentlyPlaying = _currentPlayingShlokaId == shlokaId;

    if (isCurrentlyPlaying && _playbackState == PlaybackState.playing) {
      await _audioPlayer.pause();
      return;
    }
    if (isCurrentlyPlaying && _playbackState == PlaybackState.paused) {
      await _audioPlayer.play();
      return;
    }

    // Stop the player but don't notify listeners yet to prevent a flicker state.
    await _stop(notify: false);
    _currentPlayingShlokaId = shlokaId;
    _setPlaybackState(PlaybackState.loading);

    try {
      final assetPath = await _getShlokaAssetPath(shloka);
      // If the asset path is null (e.g., download failed or not yet complete),
      // set an error state and stop.
      if (assetPath == null) {
        debugPrint("Could not get asset path for shloka $shlokaId. Asset might not be ready.");
        _setPlaybackState(PlaybackState.error);
        return;
      }
      
      // Create the MediaItem tag required by just_audio_background
      final mediaItem = MediaItem(
        id: shlokaId,
        album: "Chapter ${shloka.chapterNo}: ${StaticData.geetaAdhyay[int.parse(shloka.chapterNo) - 1]}",
        title: "Shloka ${shloka.chapterNo}.${shloka.shlokNo}",
        artist: shloka.speaker ?? "Gita Recitation",
      );

      // Determine if it's a local asset or a file path from asset_delivery
      final uri = (_useLocalAssets || Platform.isIOS) ? Uri.parse('asset:///$assetPath') : Uri.file(assetPath);
      
      // Use setAudioSource with the tagged URI
      final source = AudioSource.uri(uri, tag: mediaItem);
      await _audioPlayer.setAudioSource(source);
      await _audioPlayer.play();
    } catch (e, s) {
      debugPrint("[AUDIO_PLAYBACK] Error playing shloka: $e");
      debugPrint("[AUDIO_PLAYBACK] Stack trace: $s");
      _setPlaybackState(PlaybackState.error);
    }
  }

  Future<void> initiateChapterAudioDownload(int chapterNumber) async {
    if (_useLocalAssets || Platform.isIOS) return;
    final packName = _getPackName(chapterNumber);
    final currentStatus = getChapterPackStatus(chapterNumber);

    debugPrint("[ASSET_DELIVERY] User initiated download for chapter $chapterNumber (pack: $packName). Current status: $currentStatus");

    // Don't re-initiate if already pending or downloading
    if (currentStatus == AssetPackStatus.downloading || currentStatus == AssetPackStatus.pending) {
      debugPrint("[ASSET_DELIVERY] Download for $packName is already in progress. Ignoring request.");
      return;
    }

    // Set status to pending immediately for instant UI feedback
    _packStatus[packName] = AssetPackStatus.pending;
    notifyListeners();
    debugPrint("[ASSET_DELIVERY] Set $packName status to PENDING for UI feedback.");

    try {
      // Use fetch() to initiate the download, as per the plugin example.
      // This is a "fire-and-forget" call. The listener will handle status updates.
      await AssetDelivery.fetch(packName); 
    } catch (e, s) {
      debugPrint("[ASSET_DELIVERY] CRITICAL ERROR initiating download for chapter $chapterNumber: $e");
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
    // We'll assume they are not downloaded and let getShlokaAssetPath figure it out.
    final packNames = List.generate(18, (i) => _getPackName(i + 1));
    for (final packName in packNames) {
      // Initialize all to notDownloaded. The status will be updated by the listener
      // if a download is in progress or when one is initiated.
      _packStatus[packName] = AssetPackStatus.notDownloaded;
    }
    notifyListeners();
    // This listener will inform us of the status of any active or future downloads.
    debugPrint("[ASSET_DELIVERY] Registering for asset pack status updates.");
    AssetDelivery.getAssetPackStatus(_updateStatusFromMap);
  }

  // NEW: Extracted the status update logic into a reusable helper method.
  void _applyStatusUpdate(String packName, String? statusString, double? progress) {
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
    debugPrint("[ASSET_DELIVERY_LISTENER] Received status update with null packName. Applying workaround...");
    String? activeDownloadPackName;
    try {
      activeDownloadPackName = _packStatus.entries
          .firstWhere(
            (entry) => entry.value == AssetPackStatus.pending || entry.value == AssetPackStatus.downloading,
          )
          .key;
    } on StateError {
      // This is expected if no download is active.
      activeDownloadPackName = null;
    }

    if (activeDownloadPackName != null) {
      debugPrint("[ASSET_DELIVERY_LISTENER] Workaround: Found active pack '$activeDownloadPackName'. Applying status update.");
      _applyStatusUpdate(activeDownloadPackName, statusString, progress);
    } else {
      debugPrint("[ASSET_DELIVERY_LISTENER] Workaround failed: Could not find an active download to apply the status to.");
    }
  }

  void _listenToPlayerState() {
    _audioPlayer.playerStateStream.listen((state) {
      // The 'playing' boolean is the source of truth for playback activity.
      final isPlaying = state.playing;

      switch (state.processingState) {
        case ProcessingState.idle:
          // This state is ambiguous and can be emitted during transitions.
          // It's safer to not react to it directly. Errors and completions are handled elsewhere.
          break;
        case ProcessingState.completed:
          // The track finished playing naturally. This is a definitive stop.
          _stop();
          break;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          _setPlaybackState(PlaybackState.loading);
          break;
        case ProcessingState.ready:
          // The player is ready. The 'isPlaying' boolean determines the final state.
          _setPlaybackState(isPlaying ? PlaybackState.playing : PlaybackState.paused);
          break;
      }
    });
  }

  Future<void> _stop({bool notify = true}) async {
    await _audioPlayer.stop();
    _currentPlayingShlokaId = null;
    _setPlaybackState(PlaybackState.stopped, notify: notify);
  }

  void _setPlaybackState(PlaybackState state, {bool notify = true}) {
    if (_playbackState != state) {
      debugPrint("[AUDIO_PROVIDER] State changing from $_playbackState to $state for ID $_currentPlayingShlokaId");
      _playbackState = state;
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
      debugPrint("[ASSET_DELIVERY] Successfully got asset pack path for $packName: $assetPackPath");
      if (assetPackPath == null) {
        throw Exception('AssetDelivery.getAssetPackPath returned null. The pack is not available on the device.');
      }
      return assetPackPath;
    } catch (e, s) {
      debugPrint("[ASSET_DELIVERY] FAILED to get asset pack path for $packName. Error: $e");
      debugPrint("[ASSET_DELIVERY] Stack trace: $s");
      // Re-throw the exception to be caught by the caller (initiateChapterAudioDownload)
      rethrow;
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
      if (_useLocalAssets || Platform.isIOS) {
        return 'assets/audio/$packName/ch${chapterPadded}_sh$shlokPadded.opus';
      } else {
        // Use the new helper to get the base path for the chapter.
        final assetPackPath = await _getShlokaAssetPathForChapter(chapter);
        if (assetPackPath == null) {
          debugPrint("[ASSET_DELIVERY] Base asset pack path for chapter $chapter is null. Cannot construct shloka path.");
          return null;
        }
        // IMPORTANT: The filename here must exactly match the file in your asset pack's assets folder.
        final finalPath = '$assetPackPath/ch${chapterPadded}_sh$shlokPadded.opus';
        debugPrint("[ASSET_DELIVERY] Constructed final path for playback: $finalPath");
        return finalPath;
      }
    } catch (e, s) {
      debugPrint("[ASSET_DELIVERY] CRITICAL ERROR in _getShlokaAssetPath: $e");
      debugPrint("[ASSET_DELIVERY] Stack trace: $s");
      return null;
    }
  }
}