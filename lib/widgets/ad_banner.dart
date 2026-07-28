import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_config.dart';

/// AdMob 배너 (전 화면 하단 공통)
/// - Android: google_mobile_ads 실제 배너 표시
/// - 웹 미리보기: 은은한 플레이스홀더 표시
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _failed = true);
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Android에서 광고 로드 성공 → 실제 배너 표시
    if (!kIsWeb && _loaded && _bannerAd != null) {
      return Container(
        height: 54,
        width: double.infinity,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }

    // 웹 미리보기 / 로딩 중 / 로드 실패 → 플레이스홀더
    return Container(
      height: 54,
      width: double.infinity,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('AD',
                style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(width: 8),
          Text(_failed ? '광고 준비 중' : '광고 영역',
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFAEAEB2))),
        ],
      ),
    );
  }
}
