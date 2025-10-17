import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/widgets.dart';

typedef AdManagerConfigProvider = Future<AdManagerConfig> Function();

class AdManagerConfig {
  const AdManagerConfig({required this.sdkKey, required this.bannerAdUnitId});

  final String sdkKey;
  final String bannerAdUnitId;
}

class AdManager {
  AdManager({required AdManagerConfigProvider configProvider})
      : _configProvider = configProvider;

  final AdManagerConfigProvider _configProvider;

  bool _initializing = false;
  bool _initialized = false;
  bool _bannerLoaded = false;
  AdManagerConfig? _config;

  Future<void> initialize() async {
    if (_initialized || _initializing) {
      return;
    }

    _initializing = true;
    _config = await _configProvider();
    final config = _config;
    if (config == null) {
      _initializing = false;
      return;
    }

    await AppLovinMAX.initialize(config.sdkKey);
    _initializing = false;
    _initialized = true;

    AppLovinMAX.setBannerListener(AdViewAdListener(
      onAdLoadedCallback: (_) {
        _bannerLoaded = true;
      },
      onAdLoadFailedCallback: (_, __) {
        _bannerLoaded = false;
      },
      onAdClickedCallback: (_) {},
      onAdExpandedCallback: (_) {},
      onAdCollapsedCallback: (_) {},
    ));

    AppLovinMAX.loadBanner(config.bannerAdUnitId);
  }

  Future<void> preloadBanner() async {
    if (!_initialized) {
      await initialize();
    }

    final config = _config;
    if (config == null || _bannerLoaded) {
      return;
    }

    AppLovinMAX.loadBanner(config.bannerAdUnitId);
  }

  Widget buildBanner({Key? key}) {
    final config = _config;
    if (!_initialized || config == null) {
      return const SizedBox.shrink();
    }

    return MaxAdView(
      key: key,
      adUnitId: config.bannerAdUnitId,
      adFormat: AdFormat.banner,
      listener: AdViewAdListener(
        onAdLoadedCallback: (_) {
          _bannerLoaded = true;
        },
        onAdLoadFailedCallback: (_, __) {
          _bannerLoaded = false;
        },
        onAdClickedCallback: (_) {},
        onAdExpandedCallback: (_) {},
        onAdCollapsedCallback: (_) {},
      ),
    );
  }
}
