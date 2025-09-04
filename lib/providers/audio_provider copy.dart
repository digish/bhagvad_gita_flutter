import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:asset_delivery/asset_delivery.dart';
import '../models/shloka_result.dart';

// A simple utility to get shloka counts per chapter.
const Map<int, int> _shlokaCounts = {
  1: 47, 2: 72, 3: 43, 4: 42, 5: 29, 6: 47, 7: 30, 8: 28, 9: 34,
  10: 42, 11: 55, 12: 20, 13: 35, 14: 27, 15: 20, 16: 24, 17: 28, 18: 78
};

// --- DEVELOPMENT SWITCH ---
// Set this to true to use local files from your 'assets/audio/' folder.
// Set this to false to use the real Google Play Asset Delivery system.
const bool _useLocalAssets = true;


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
    _initializeAndListen();
    _listenToPlayerState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- PUBLIC METHODS ---

  AssetPackStatus getChapterPackStatus(int chapterNumber) {
    // If using local assets, always report them as 'downloaded'.
    if (_useLocalAssets) return AssetPackStatus.downloaded;
    
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

    await _stop();
    _currentPlayingShlokaId = shlokaId;
    _setPlaybackState(PlaybackState.loading);

    try {
      final assetPath = await _getShlokaAssetPath(shloka);
      if (assetPath != null) {
        // The setAsset method works for both local Flutter assets and file paths.
        await _audioPlayer.setAsset(assetPath);
        await _audioPlayer.play();
      } else {
        // If the path is null, it means a download is needed (for non-local assets)
        final chapterNumber = int.parse(shloka.chapterNo);
        initiateChapterAudioDownload(chapterNumber);
        await _stop();
      }
    } catch (e) {
      debugPrint("Error playing shloka: $e");
      _setPlaybackState(PlaybackState.error);
    }
  }

  void initiateChapterAudioDownload(int chapterNumber) {
    // This function does nothing if we are using local assets.
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

  Future<void> _initializeAndListen() async {
    if (_useLocalAssets) {
      // In local mode, we don't need to check for downloads.
      notifyListeners();
      return;
    }

    // This logic is for Play Asset Delivery only.
    for (var i = 1; i <= 18; i++) {
      final packName = _getPackName(i);
      try {
        await AssetDelivery.getAssetPackPath(
          assetPackName: packName,
          count: _shlokaCounts[i] ?? 0,
          namingPattern: 'ch${i.toString().padLeft(2, '0')}_sh',
          fileExtension: 'mp3',
        );
        _packStatus[packName] = AssetPackStatus.downloaded;
      } catch (e) {
        _packStatus[packName] = AssetPackStatus.notDownloaded;
      }
    }
    notifyListeners();
    AssetDelivery.getAssetPackStatus((statusMap) {
      _updateStatusFromMap(statusMap);
    });
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
      default:
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
        // Construct the path for local Flutter assets.
        return 'assets/audio/$packName/ch${chapterPadded}_sh$shlokPadded.mp3';
      } else {
        // Check if the asset pack is downloaded before getting the path.
        if (getChapterPackStatus(chapter) != AssetPackStatus.downloaded) {
          return null; // Not downloaded, so path is not available.
        }
        final assetPackPath = await AssetDelivery.getAssetPackPath(
          assetPackName: packName,
          count: _shlokaCounts[chapter] ?? 0,
          namingPattern: 'ch${chapterPadded}_sh',
          fileExtension: 'mp3',
        );
        return '$assetPackPath/ch${chapterPadded}_sh$shlokPadded.mp3';
      }
    } catch (e) {
      debugPrint("Could not get asset path: $e");
      return null;
    }
  }
}

