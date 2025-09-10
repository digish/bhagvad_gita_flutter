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
    if (!_useLocalAssets) {
      await _initializeAssetDeliveryListeners();
    }
    
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
    if (_useLocalAssets) return AssetPackStatus.downloaded;
    final packName = _getPackName(chapterNumber);
    return _packStatus[packName] ?? AssetPackStatus.unknown;
  }

  double getChapterDownloadProgress(int chapterNumber) {
    final packName = _getPackName(chapterNumber);
    return _downloadProgress[packName] ?? 0.0;
  }

  // MODIFIED: This is the main change to support background audio
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

    await _stop();
    _currentPlayingShlokaId = shlokaId;
    _setPlaybackState(PlaybackState.loading);

    try {
      final assetPath = await _getShlokaAssetPath(shloka);
      if (assetPath == null) {
        final chapterNumber = int.parse(shloka.chapterNo);
        initiateChapterAudioDownload(chapterNumber);
        await _stop();
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
      final uri = _useLocalAssets ? Uri.parse('asset:///$assetPath') : Uri.file(assetPath);
      
      // Use setAudioSource with the tagged URI
      final source = AudioSource.uri(uri, tag: mediaItem);
      await _audioPlayer.setAudioSource(source);
      
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing shloka: $e");
      _setPlaybackState(PlaybackState.error);
    }
  }

  void initiateChapterAudioDownload(int chapterNumber) {
    if (_useLocalAssets) return;
    final packName = _getPackName(chapterNumber);
    if (getChapterPackStatus(chapterNumber) == AssetPackStatus.downloading) {
      return;
    }
    _packStatus[packName] = AssetPackStatus.downloading;
    _downloadProgress[packName] = 0.0;
    notifyListeners();
    AssetDelivery.fetch(packName);
  }

  // --- PRIVATE HELPERS ---

  // RENAMED for clarity
  Future<void> _initializeAssetDeliveryListeners() async {
    for (var i = 1; i <= 18; i++) {
      final packName = _getPackName(i);
      try {
        await AssetDelivery.getAssetPackPath(
          assetPackName: packName,
          count: _shlokaCounts[i] ?? 0,
          namingPattern: 'ch${i.toString().padLeft(2, '0')}_sh',
          fileExtension: 'opus',
        );
        _packStatus[packName] = AssetPackStatus.downloaded;
      } catch (e) {
        _packStatus[packName] = AssetPackStatus.notDownloaded;
      }
    }
    notifyListeners();
    AssetDelivery.getAssetPackStatus(_updateStatusFromMap);
  }

  void _updateStatusFromMap(Map<dynamic, dynamic> statusMap) {
    final packName = statusMap['assetPackName'] as String?;
    final statusString = statusMap['status'] as String?;
    final progress = statusMap['downloadProgress'] as double?;

    if (packName == null) return;
    switch (statusString) {
      case 'PENDING':
      case 'DOWNLOADING':
        _packStatus[packName] = AssetPackStatus.downloading;
        if (progress != null) _downloadProgress[packName] = progress;
        break;
      case 'COMPLETED':
        _packStatus[packName] = AssetPackStatus.downloaded;
        _downloadProgress.remove(packName);
        break;
      case 'FAILED':
        _packStatus[packName] = AssetPackStatus.failed;
        _downloadProgress.remove(packName);
        break;
    }
    notifyListeners();
  }

  void _listenToPlayerState() {
    _audioPlayer.playerStateStream.listen((state) {
      if (_currentPlayingShlokaId == null) return;
      switch (state.processingState) {
        case ProcessingState.idle:
        case ProcessingState.completed:
          _stop();
          break;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          _setPlaybackState(PlaybackState.loading);
          break;
        case ProcessingState.ready:
          _setPlaybackState(
              state.playing ? PlaybackState.playing : PlaybackState.paused);
          break;
      }
    });
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    _currentPlayingShlokaId = null;
    _setPlaybackState(PlaybackState.stopped);
  }

  void _setPlaybackState(PlaybackState state) {
    if (_playbackState != state) {
      _playbackState = state;
      notifyListeners();
    }
  }

  String _getPackName(int chapterNumber) => 'Chapter${chapterNumber}_audio';

  Future<String?> _getShlokaAssetPath(ShlokaResult shloka) async {
    try {
      final chapter = int.parse(shloka.chapterNo);
      final shlokNum = int.parse(shloka.shlokNo);
      final packName = _getPackName(chapter);
      final chapterPadded = chapter.toString().padLeft(2, '0');
      final shlokPadded = shlokNum.toString().padLeft(2, '0');

      if (_useLocalAssets) {
        return 'assets/audio/$packName/ch${chapterPadded}_sh$shlokPadded.opus';
      } else {
        if (getChapterPackStatus(chapter) != AssetPackStatus.downloaded) {
          return null;
        }
        final assetPackPath = await AssetDelivery.getAssetPackPath(
          assetPackName: packName,
          count: _shlokaCounts[chapter] ?? 0,
          namingPattern: 'ch${chapterPadded}_sh',
          fileExtension: 'opus',
        );
        return '$assetPackPath/ch${chapterPadded}_sh$shlokPadded.opus';
      }
    } catch (e) {
      debugPrint("Could not get asset path: $e");
      return null;
    }
  }
}