import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../auth/profile_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  String _tracker = '습관 트래커';

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    try {
      final profile = await ProfileService.instance.getProfile();
      if (!mounted) return;
      final nick = profile.nickname.trim();
      setState(() {
        _tracker = nick.isNotEmpty ? '$nick의 습관 트래커' : '습관 트래커';
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A34), Color(0xFF2D5244), Color(0xFF3E6B4E)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tracker,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 4),
                    Text(
                      'AI가 일기에서 자동으로 감지한 습관이에요',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // Habit heatmap
              _HabitHeatmap()
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.05, end: 0),

              const SizedBox(height: 28),

              // Streak stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFFF8C42),
                      label: '현재 연속',
                      value: '6일',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.emoji_events_rounded,
                      iconColor: const Color(0xFFFFD700),
                      label: '최장 연속',
                      value: '14일',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.calendar_month_rounded,
                      iconColor: AppColors.primary,
                      label: '이번 달',
                      value: '22일',
                    ),
                  ),
                ],
              ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 32),

              // Detected habits
              Text(
                '감지된 습관',
                style: Theme.of(context).textTheme.titleMedium,
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 16),

              ..._habits.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HabitTile(habit: entry.value)
                      .animate(delay: Duration(milliseconds: 450 + entry.key * 80))
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.03, end: 0),
                );
              }),
            ],          // inner Column children
          ),            // inner Column
        ),              // SingleChildScrollView
        ),              // Expanded
        ],              // outer Column children
      ),                // outer Column
    );
  }
}

// ─── Habit Heatmap (GitHub-style) ───────────────────────────────────────────

class _HabitHeatmap extends StatelessWidget {
  final _random = Random(42);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5월 기록 현황',
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text('적음', style: GoogleFonts.notoSansKr(fontSize: 11, color: AppColors.textHint)),
                  const SizedBox(width: 4),
                  ...[AppColors.heatmap0, AppColors.heatmap1, AppColors.heatmap2, AppColors.heatmap3, AppColors.heatmap4].map(
                    (c) => Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('많음', style: GoogleFonts.notoSansKr(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calendar grid (5 weeks × 7 days)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 35,
            itemBuilder: (context, i) {
              final day = i - 2; // offset so month starts on Wednesday
              final isValidDay = day >= 0 && day < 31;
              final isToday = day == 3;
              final level = isValidDay && day <= 3 ? _random.nextInt(5) : 0;
              final colors = [
                AppColors.heatmap0,
                AppColors.heatmap1,
                AppColors.heatmap2,
                AppColors.heatmap3,
                AppColors.heatmap4,
              ];

              return Container(
                decoration: BoxDecoration(
                  color: isValidDay ? colors[level] : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
                ),
                child: isValidDay
                    ? Center(
                        child: Text(
                          '${day + 1}',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            color: level >= 3
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.notoSansKr(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Habit Tile ─────────────────────────────────────────────────────────────

class _HabitTile extends StatelessWidget {
  final _Habit habit;
  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: habit.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(habit.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '이번 달 ${habit.count}회 감지',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Mini bar
          SizedBox(
            width: 60,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: habit.count / 30,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(habit.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Habit {
  final String emoji;
  final String name;
  final int count;
  final Color color;
  const _Habit(this.emoji, this.name, this.count, this.color);
}

const _habits = [
  _Habit('🏃', '운동', 18, AppColors.primary),
  _Habit('📖', '독서', 12, Color(0xFF5B8DEF)),
  _Habit('😴', '숙면', 22, Color(0xFF9B7FDB)),
  _Habit('🍎', '건강 식사', 15, Color(0xFFFF8C42)),
  _Habit('✍️', '공부', 8, Color(0xFF4ECDC4)),
];
