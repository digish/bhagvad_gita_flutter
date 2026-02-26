import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  // ✨ Added: Track ad status for UI verification
  final ValueNotifier<String> adStatus = ValueNotifier<String>('idle');

  // AdMob IDs
  String get rewardedAdUnitId {
    // 1. Use Test IDs in Debug Mode
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/5224354917'; // Android Test ID
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test ID
      }
    }

    // 2. Use Production IDs in Release Mode
    if (Platform.isAndroid) {
      return 'ca-app-pub-9968933785213782/2800557456'; // Production Android ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9968933785213782/6979367816'; // Production iOS ID
    }

    throw UnsupportedError('Unsupported platform');
  }

  void loadRewardedAd() {
    if (_isAdLoading || _rewardedAd != null) return;

    _isAdLoading = true;
    adStatus.value = 'downloading';
    debugPrint('🔵 AdService: Requesting Reward Ad download...');

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('🟢 AdService: Reward Ad downloaded & ready.');
          _rewardedAd = ad;
          _isAdLoading = false;
          adStatus.value = 'ready';
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('🔴 AdService: Reward Ad download failed: $error');
          _rewardedAd = null;
          _isAdLoading = false;
          adStatus.value = 'failed';
        },
      ),
    );
  }

  void showRewardedAd({
    required Function(RewardItem reward) onRewardEarned,
    Function()? onAdFailedToShow,
  }) {
    if (_rewardedAd == null) {
      debugPrint(
        'Warning: Attempted to show rewarded ad before it was loaded.',
      );
      if (onAdFailedToShow != null) onAdFailedToShow();
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('RewardedAd showed.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('RewardedAd dismissed.');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Load the next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        if (onAdFailedToShow != null) onAdFailedToShow();
        loadRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) => onRewardEarned(reward),
    );
  }
}
