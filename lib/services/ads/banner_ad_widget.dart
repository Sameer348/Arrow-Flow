import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'ad_config.dart';
import 'admob_service.dart';

/// Anchored adaptive banner. Collapses to zero height when ads are disabled,
/// not ready, or fail — never leaves an empty box or blocks layout.
/// Only use on menu screens (Home, Level Map, Shop), never over gameplay.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;
  int? _width;
  bool _attempted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width != _width) {
      _width = width;
      _load();
    }
  }

  Future<void> _load() async {
    final ads = context.read<AdMobService>();
    if (!ads.bannersAllowed) return;
    _attempted = true;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(_width!);
    if (!mounted || size == null) return;
    await _ad?.dispose();
    _loaded = false;
    final ad = BannerAd(
      adUnitId: AdConfig.bannerId,
      size: size,
      request: ads.request,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    _ad = ad;
    try {
      await ad.load();
    } on Object {
      if (mounted) setState(() => _ad = null);
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdMobService>();
    final ad = _ad;
    if (!ads.bannersAllowed) return const SizedBox.shrink();
    if (ad == null) {
      // Ads became available after this widget was built.
      if (_width != null && !_attempted) {
        _attempted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _ad == null) _load();
        });
      }
      return const SizedBox.shrink();
    }
    if (!_loaded) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
