import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const _testDeviceIds = [
    'SIMULATOR',
    'GADSimulatorID',
    '796a536b6e8b1c28266f93c57fa69224',
  ];

  static const _keywords = [
    '병원',
    '의료',
    '건강',
    '약국',
    '클리닉',
    'hospital',
    'health',
    'medical',
  ];

  // ── 스플래시 배너 광고 단위 ID ──────────────────────────────────────────────
  static String get splashAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-3875380687802538/6756098739';
    } else {
      return 'ca-app-pub-3875380687802538/5748542934';
    }
  }

  // ── 일기 목록 배너 광고 단위 ID ─────────────────────────────────────────────
  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-3875380687802538/2845363210';
    } else {
      return 'ca-app-pub-3875380687802538/2677842257';
    }
  }

  Future<void> initialize() async {
    if (kIsWeb) return;
    final initStatus = await MobileAds.instance.initialize();
    initStatus.adapterStatuses.forEach((key, value) {
      debugPrint('[AdMob] $key: ${value.state} — ${value.description}');
    });
    // 디버그 빌드에서는 시뮬레이터와 등록된 실기기를 테스트 기기로 사용합니다.
    if (kDebugMode) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
    }
  }
}

/// 스플래시 화면 하단 배너 광고
class SplashBannerAd extends StatefulWidget {
  const SplashBannerAd({super.key});

  @override
  State<SplashBannerAd> createState() => _SplashBannerAdState();
}

class _SplashBannerAdState extends State<SplashBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return;
    _bannerAd = BannerAd(
      adUnitId: AdService.splashAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(keywords: AdService._keywords),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            '[AdMob] 스플래시 배너 로드 실패: ${error.message} (code: ${error.code})',
          );
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// 설정 화면 하단 배너 광고 위젯 (Free/Trial 유저용)
class SettingsBannerAd extends StatefulWidget {
  const SettingsBannerAd({super.key});

  @override
  State<SettingsBannerAd> createState() => _SettingsBannerAdState();
}

class _SettingsBannerAdState extends State<SettingsBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return;
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(keywords: AdService._keywords),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E6E0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            color: const Color(0xFFEEECE8),
            child: const Text(
              '광고',
              style: TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
            ),
          ),
          SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ],
      ),
    );
  }
}

/// 일기 목록에 삽입되는 배너 광고 위젯 (Free/Trial 유저용)
class JournalBannerAd extends StatefulWidget {
  const JournalBannerAd({super.key});

  @override
  State<JournalBannerAd> createState() => _JournalBannerAdState();
}

class _JournalBannerAdState extends State<JournalBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return;
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(keywords: AdService._keywords),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: const Color(0xFFF5F5F5),
            child: const Text(
              '광고',
              style: TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
            ),
          ),
          SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ],
      ),
    );
  }
}
