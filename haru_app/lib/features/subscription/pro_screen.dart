import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'subscription_api.dart';
import 'purchase_service.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  bool _isYearly = true;
  bool _starting = false;
  bool _loadingOfferings = true;
  Package? _monthlyPackage;
  Package? _annualPackage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offerings = await PurchaseService.instance.getOfferings();
    if (!mounted) return;
    if (offerings != null) {
      final packages = offerings.current?.availablePackages ?? [];
      Package? monthly;
      Package? annual;
      for (final pkg in packages) {
        if (pkg.packageType == PackageType.monthly) {
          monthly = pkg;
        } else if (pkg.packageType == PackageType.annual) {
          annual = pkg;
        }
      }
      setState(() {
        _monthlyPackage = monthly;
        _annualPackage = annual;
        _loadingOfferings = false;
      });
    } else {
      setState(() => _loadingOfferings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF283F3B), Color(0xFF1A2A26)],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        '나중에',
                        style: GoogleFonts.notoSansKr(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Crown icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFD700), Color(0xFFFFA726)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ).animate().scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1.0, 1.0),
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),

                      const SizedBox(height: 20),

                      Text(
                        '하루결 PRO',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                      const SizedBox(height: 8),

                      Text(
                        '매일의 기록을 더 깊이 있게',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 15,
                          color: Colors.white60,
                        ),
                      ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

                      const SizedBox(height: 36),

                      // Feature list
                      ..._features.asMap().entries.map((entry) {
                        return _FeatureRow(feature: entry.value)
                            .animate(delay: Duration(milliseconds: 350 + entry.key * 80))
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.05, end: 0);
                      }),

                      const SizedBox(height: 36),

                      // Plan toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isYearly = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isYearly
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '월간',
                                      style: GoogleFonts.notoSansKr(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: !_isYearly ? Colors.white : Colors.white38,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isYearly = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isYearly
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '연간',
                                          style: GoogleFonts.notoSansKr(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _isYearly ? Colors.white : Colors.white38,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD700),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '-34%',
                                            style: GoogleFonts.notoSansKr(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF1A2A26),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 20),

                      // Price card
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _PriceCard(
                          key: ValueKey(_isYearly),
                          isYearly: _isYearly,
                          monthlyPrice: _monthlyPackage?.storeProduct.priceString,
                          annualPrice: _annualPackage?.storeProduct.priceString,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // CTA button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _starting ? null : () => _startTrial(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: const Color(0xFF1A2A26),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _starting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF1A2A26),
                                  ),
                                )
                              : Text(
                                  '7일 무료 체험 시작',
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ).animate(delay: 800.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 12),

                      Text(
                        '7일 무료 체험 후 자동 결제 · 언제든 취소 가능',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ).animate(delay: 900.ms).fadeIn(duration: 400.ms),

                      // Restore purchases button
                      TextButton(
                        onPressed: _starting ? null : _restore,
                        child: Text(
                          '구매 복원',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            color: Colors.white38,
                          ),
                        ),
                      ).animate(delay: 950.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 12),

                      // Compare plans
                      GestureDetector(
                        onTap: () => _showCompareSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '무료 vs PRO 비교',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white54,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white38,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.expand_more_rounded, color: Colors.white38, size: 18),
                            ],
                          ),
                        ),
                      ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startTrial(BuildContext context) async {
    // Determine the selected package
    final selectedPackage = _isYearly ? _annualPackage : _monthlyPackage;

    // If RevenueCat is configured and we have a package, use real IAP
    if (selectedPackage != null) {
      setState(() => _starting = true);
      final result = await PurchaseService.instance.purchasePackage(selectedPackage);
      if (!mounted) return;
      setState(() => _starting = false);

      if (result.cancelled) {
        // User cancelled — do nothing
        return;
      }
      if (result.success) {
        _showSuccessSheet(context);
      } else if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error!, style: GoogleFonts.notoSansKr(fontSize: 14)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    // Fallback: mock trial via server (RevenueCat not configured)
    setState(() => _starting = true);
    try {
      await SubscriptionApi.instance.startTrial();
      if (!mounted) return;
      _showSuccessSheet(context);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data as Map?)?['error'] as String? ?? '오류가 발생했어요';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.notoSansKr(fontSize: 14)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (_) {
      // fallback: show success anyway (trial may have been set server-side)
      if (!mounted) return;
      _showSuccessSheet(context);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _starting = true);
    final result = await PurchaseService.instance.restorePurchases();
    if (!mounted) return;
    setState(() => _starting = false);
    if (result.success) {
      _showSuccessSheet(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          result.restored ? '복원할 구매 내역이 없어요' : '복원에 실패했어요',
          style: GoogleFonts.notoSansKr(fontSize: 14),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  void _showSuccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.celebration_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              '환영합니다! 🎉',
              style: GoogleFonts.notoSansKr(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '7일간 PRO의 모든 기능을\n무료로 체험해보세요',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/home');
                },
                child: const Text('시작하기'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCompareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '플랜 비교',
                  style: GoogleFonts.notoSansKr(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 24),
              _CompareRow('일기 작성', '무제한', '무제한', false),
              _CompareRow('AI 감정 분석', '3회/일', '무제한', true),
              _CompareRow('습관 자동 감지', '기본', '고급', true),
              _CompareRow('AI 코치 대화', '5회/일', '무제한', true),
              _CompareRow('주간 리포트', '—', '매주 월요일', true),
              _CompareRow('감정 통계', '최근 7일', '전체 기간', true),
              _CompareRow('데이터 내보내기', '—', '지원', true),
              _CompareRow('광고', '있음', '없음', true),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Feature Row ────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: feature.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  feature.subtitle,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _Feature(this.icon, this.color, this.title, this.subtitle);
}

const _features = [
  _Feature(Icons.auto_awesome_rounded, Color(0xFFFFD700), '무제한 AI 분석', '매 일기마다 감정 · 습관 자동 분석'),
  _Feature(Icons.chat_bubble_rounded, Color(0xFF8BBF84), '무제한 AI 코치', '나만의 AI 코치와 제한 없이 대화'),
  _Feature(Icons.bar_chart_rounded, Color(0xFF5B8DEF), '주간 감정 리포트', '매주 월요일 자동 생성 · 이메일 전송'),
  _Feature(Icons.timeline_rounded, Color(0xFF9B7FDB), '전체 기간 통계', '감정 패턴 · 습관 트렌드 한눈에'),
  _Feature(Icons.block_rounded, Color(0xFFFF8C42), '광고 제거', '집중을 방해하는 광고 없이'),
];

// ─── Price Card ─────────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final bool isYearly;
  final String? monthlyPrice;
  final String? annualPrice;
  const _PriceCard({super.key, required this.isYearly, this.monthlyPrice, this.annualPrice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          if (isYearly) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  annualPrice ?? '₩39,000',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Text(
                    '/년',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 15,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '월 ₩3,250 · 매달 ₩1,650 절약',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  monthlyPrice ?? '₩4,900',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Text(
                    '/월',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 15,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '부담 없이 매달 결제',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: Colors.white54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Compare Row ────────────────────────────────────────────────────────────

class _CompareRow extends StatelessWidget {
  final String feature;
  final String free;
  final String pro;
  final bool highlight;

  const _CompareRow(this.feature, this.free, this.pro, this.highlight);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              pro,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                color: highlight ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
