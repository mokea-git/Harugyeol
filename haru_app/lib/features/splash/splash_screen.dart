import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/ads/ad_service.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) context.go('/auth-gate');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                // Leaf icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    size: 48,
                    color: Color(0xFF8BBF84),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 28),

                // App name
                Text(
                  '하루결',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut),

                const SizedBox(height: 12),

                // Slogan
                Text(
                  '오늘 하루의 결을 읽어드립니다',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 800.ms),

                const SizedBox(height: 64),

                // Loading dots
                SizedBox(
                  width: 48,
                  height: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(
                            delay: Duration(milliseconds: 1200 + i * 200),
                            onPlay: (c) => c.repeat(reverse: true),
                          )
                          .scaleXY(begin: 0.6, end: 1.0, duration: 500.ms)
                          .then()
                          .scaleXY(begin: 1.0, end: 0.6, duration: 500.ms);
                    }),
                  ),
                ),
                    ],
                  ),
                ),
              ),
              // 스플래시 하단 배너 광고
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: SplashBannerAd(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
