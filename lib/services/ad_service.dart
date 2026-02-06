import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  // AdMob Test IDs
  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  void loadRewardedAd() {
    if (_isAdLoading || _rewardedAd != null) return;

    _isAdLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('RewardedAd loaded.');
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isAdLoading = false;
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
