import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../auth/profile_service.dart';
import '../journal/journal_api.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  String _tracker = '습관 트래커';
  bool _loading = true;
  String? _error;
  List<JournalEntry> _journals = const [];

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _loadJournals();
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

  Future<void> _loadJournals() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final journals = await JournalApi.instance.listJournals();
      if (!mounted) return;
      setState(() {
        _journals = journals;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '습관 데이터를 불러오지 못했어요';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadJournals,
        edgeOffset: 80,
        child: Column(
          children: [
            // ── 헤더 ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A34),
                    Color(0xFF2D5244),
                    Color(0xFF3E6B4E),
                  ],
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

            // ── 본문 ─────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _error != null
                      ? _buildError()
                      : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        const Center(child: Text('😢', style: TextStyle(fontSize: 44))),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _error!,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: _loadJournals,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('다시 시도'),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final stats = _HabitStats.fromJournals(_journals);
    final habits = _aggregateHabits(_journals);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 히트맵
          _HabitHeatmap(journals: _journals)
              .animate(delay: 100.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // 통계
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFFF8C42),
                  label: '현재 연속',
                  value: '${stats.currentStreak}일',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFFFD700),
                  label: '최장 연속',
                  value: '${stats.maxStreak}일',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_month_rounded,
                  iconColor: AppColors.primary,
                  label: '이번 달',
                  value: '${stats.monthCount}일',
                ),
              ),
            ],
          ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

          const SizedBox(height: 28),

          // 감지된 습관
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '감지된 습관',
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (habits.isNotEmpty)
                Text(
                  '총 ${habits.length}개',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
            ],
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 14),

          if (habits.isEmpty)
            _EmptyHabits()
                .animate(delay: 350.ms)
                .fadeIn(duration: 400.ms)
          else
            ...habits.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HabitTile(habit: entry.value)
                    .animate(
                      delay: Duration(milliseconds: 350 + entry.key * 60),
                    )
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: 0.03, end: 0),
              );
            }),
        ],
      ),
    );
  }
}

// ─── 통계 계산 ───────────────────────────────────────────────────────────────

class _HabitStats {
  final int currentStreak;
  final int maxStreak;
  final int monthCount;

  const _HabitStats({
    required this.currentStreak,
    required this.maxStreak,
    required this.monthCount,
  });

  factory _HabitStats.fromJournals(List<JournalEntry> journals) {
    final dates = journals
        .map((j) => DateTime.tryParse(j.date))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();

    if (dates.isEmpty) {
      return const _HabitStats(currentStreak: 0, maxStreak: 0, monthCount: 0);
    }

    // 최장 연속
    int best = 1;
    int run = 1;
    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        run += 1;
        if (run > best) best = run;
      } else if (diff > 1) {
        run = 1;
      }
    }

    // 현재 연속 (오늘 또는 어제부터 역순으로 카운트)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateSet = dates.toSet();
    int current = 0;
    DateTime cursor = today;
    if (!dateSet.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (dateSet.contains(cursor)) {
      current += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // 이번 달
    final monthCount = dates
        .where((d) => d.year == now.year && d.month == now.month)
        .length;

    return _HabitStats(
      currentStreak: current,
      maxStreak: best,
      monthCount: monthCount,
    );
  }
}

// ─── 히트맵 ──────────────────────────────────────────────────────────────────

class _HabitHeatmap extends StatelessWidget {
  final List<JournalEntry> journals;
  const _HabitHeatmap({required this.journals});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDay = DateTime(now.year, now.month, 1);
    final firstWeekday = firstDay.weekday; // 1=월, 7=일

    // 날짜별 일기 수
    final perDay = <int, int>{};
    for (final j in journals) {
      final d = DateTime.tryParse(j.date);
      if (d == null) continue;
      if (d.year == now.year && d.month == now.month) {
        perDay[d.day] = (perDay[d.day] ?? 0) + 1;
      }
    }

    final maxCount = perDay.values.fold<int>(0, (m, v) => v > m ? v : m);

    Color levelColor(int count) {
      if (count <= 0) return AppColors.heatmap0;
      if (maxCount <= 1) return AppColors.heatmap2;
      final ratio = count / maxCount;
      if (ratio < 0.3) return AppColors.heatmap1;
      if (ratio < 0.6) return AppColors.heatmap2;
      if (ratio < 0.85) return AppColors.heatmap3;
      return AppColors.heatmap4;
    }

    final cells = firstWeekday - 1 + daysInMonth;
    final rows = (cells / 7).ceil();
    final totalCells = rows * 7;

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
                '${now.month}월 기록 현황',
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Text(
                    '적음',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ...[
                    AppColors.heatmap0,
                    AppColors.heatmap1,
                    AppColors.heatmap2,
                    AppColors.heatmap3,
                    AppColors.heatmap4,
                  ].map(
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
                  Text(
                    '많음',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 요일 헤더
          Row(
            children: ['월', '화', '수', '목', '금', '토', '일'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 10,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: totalCells,
            itemBuilder: (context, i) {
              final dayNum = i - (firstWeekday - 1) + 1;
              final isValid = dayNum >= 1 && dayNum <= daysInMonth;
              final isToday = isValid && dayNum == now.day;
              final count = isValid ? (perDay[dayNum] ?? 0) : 0;
              final color = isValid ? levelColor(count) : Colors.transparent;
              final isDark = count > 0 &&
                  (color == AppColors.heatmap3 || color == AppColors.heatmap4);

              return Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: isValid
                    ? Center(
                        child: Text(
                          '$dayNum',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 10,
                            fontWeight:
                                isToday ? FontWeight.w800 : FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : isToday
                                    ? AppColors.primary
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

// ─── 통계 카드 ───────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(14),
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
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.notoSansKr(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
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

// ─── 습관 타일 ───────────────────────────────────────────────────────────────

class _HabitTile extends StatelessWidget {
  final _Habit habit;
  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    final ratio = (habit.count / 30).clamp(0.0, 1.0);

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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${habit.count}회 감지',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(habit.color),
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

// ─── 빈 상태 ─────────────────────────────────────────────────────────────────

class _EmptyHabits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            '아직 감지된 습관이 없어요',
            style: GoogleFonts.notoSansKr(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '일기를 더 작성하면 AI가\n반복되는 습관을 자동으로 찾아줘요',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 데이터 모델 + 집계 로직 ─────────────────────────────────────────────────

class _Habit {
  final String emoji;
  final String name;
  final int count;
  final Color color;
  const _Habit(this.emoji, this.name, this.count, this.color);
}

class _HabitCategory {
  final String name;
  final String emoji;
  final List<String> keywords;
  final Color color;
  const _HabitCategory(this.name, this.emoji, this.keywords, this.color);
}

const _categories = <_HabitCategory>[
  _HabitCategory('운동', '🏃', ['운동', '헬스', '달리기', '러닝', '요가', '산책', '걷기'],
      AppColors.primary),
  _HabitCategory('독서', '📖', ['독서', '책', '읽기'], Color(0xFF5B8DEF)),
  _HabitCategory('수면', '😴', ['수면', '잠', '숙면', '취침'], Color(0xFF9B7FDB)),
  _HabitCategory('식단', '🍎', ['식사', '식단', '건강식', '아침', '점심', '저녁'],
      Color(0xFFFF8C42)),
  _HabitCategory('공부', '✍️', ['공부', '학습', '강의', '코딩', '프로그래밍'],
      Color(0xFF4ECDC4)),
  _HabitCategory('명상', '🧘', ['명상', '호흡', '마음챙김'], Color(0xFFE57373)),
  _HabitCategory('스트레스', '😮‍💨', ['스트레스', '번아웃', '긴장'], Color(0xFFB0BEC5)),
];

List<_Habit> _aggregateHabits(List<JournalEntry> journals) {
  final counter = <String, int>{};
  for (final j in journals) {
    final habits = j.analysis?.habits ?? const <String>[];
    for (final raw in habits) {
      final key = _categorize(raw);
      if (key == null) continue;
      counter[key] = (counter[key] ?? 0) + 1;
    }
  }

  final entries = counter.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return entries.map((e) {
    final cat = _categories.firstWhere(
      (c) => c.name == e.key,
      orElse: () => _HabitCategory(
        e.key,
        '✨',
        const [],
        AppColors.primary,
      ),
    );
    return _Habit(cat.emoji, cat.name, e.value, cat.color);
  }).toList();
}

String? _categorize(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return null;
  for (final c in _categories) {
    for (final kw in c.keywords) {
      if (s.contains(kw)) return c.name;
    }
  }
  // 미분류는 원본 키워드를 그대로 카테고리로 사용 (앞 2개 단어만)
  final cleaned = raw.trim();
  if (cleaned.length > 12) return null; // 너무 긴 문장은 제외
  return cleaned;
}
