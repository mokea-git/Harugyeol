import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../journal/journal_api.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  bool _loading = true;
  String? _error;
  List<JournalEntry> _journals = const [];
  List<_AnalysisItem> _analyses = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final weeklyRes = await ApiClient.instance.dio.get('/analyses/weekly');
      final journals = await JournalApi.instance.listJournals();
      final raw = weeklyRes.data;
      if (raw is! List) throw Exception('invalid response');

      final analyses = raw
          .whereType<Map>()
          .map((e) => _AnalysisItem.fromJson(e.cast<String, dynamic>()))
          .toList();

      if (!mounted) return;
      setState(() {
        _analyses = analyses;
        _journals = journals;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '주간 리포트를 불러오지 못했어요';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    final period = _periodLabel(_analyses);
    final journalCount = _journals.length;
    final charCount = _journals.fold<int>(
      0,
      (sum, j) => sum + j.content.length,
    );
    final streak = _maxStreak(_journals.map((e) => e.date).toSet().toList());
    final topEmotions = _topEmotionRatios(_analyses);
    final topHabits = _topHabits(_analyses);
    final summaryText = _summaryText(_analyses);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
              title: Text(
                '주간 리포트',
                style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        period,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF283F3B), Color(0xFF3A5A42)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI 주간 요약',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            summaryText,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 14,
                              height: 1.65,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      '감정 분포',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _EmotionBars(items: topEmotions),
                    const SizedBox(height: 22),
                    Text(
                      '기록 통계',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatCard(
                          '작성한 일기',
                          '$journalCount편',
                          Icons.edit_note_rounded,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          '총 글자 수',
                          '$charCount자',
                          Icons.text_fields_rounded,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          '연속 기록',
                          '$streak일',
                          Icons.local_fire_department_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      '이번 주 습관 TOP',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...topHabits.take(5).toList().asMap().entries.map((e) {
                      return _HabitTile(
                        rank: e.key + 1,
                        label: e.value.$1,
                        count: e.value.$2,
                      );
                    }),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisItem {
  final String journalId;
  final List<String> emotions;
  final List<String> habits;
  final String feedback;
  final DateTime createdAt;

  const _AnalysisItem({
    required this.journalId,
    required this.emotions,
    required this.habits,
    required this.feedback,
    required this.createdAt,
  });

  factory _AnalysisItem.fromJson(Map<String, dynamic> json) {
    return _AnalysisItem(
      journalId: (json['journal_id'] as String?) ?? '',
      emotions: (json['emotions'] is List)
          ? (json['emotions'] as List).whereType<String>().toList()
          : const <String>[],
      habits: (json['habits'] is List)
          ? (json['habits'] as List).whereType<String>().toList()
          : const <String>[],
      feedback: (json['feedback'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

class _EmotionBars extends StatelessWidget {
  final List<({String emotion, double ratio})> items;
  const _EmotionBars({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '이번 주 분석 데이터가 없어요',
          style: GoogleFonts.notoSansKr(fontSize: 13),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    e.emotion,
                    style: GoogleFonts.notoSansKr(fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: e.ratio < 0.05 ? 0.05 : e.ratio,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: _emotionColor(e.emotion),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(e.ratio * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.notoSansKr(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final int rank;
  final String label;
  final int count;
  const _HabitTile({
    required this.rank,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$count회',
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _periodLabel(List<_AnalysisItem> items) {
  if (items.isEmpty) return '이번 주';
  final sorted = [...items]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final first = sorted.first.createdAt;
  final last = sorted.last.createdAt;
  return '${first.month}월 ${first.day}일 ~ ${last.month}월 ${last.day}일';
}

List<({String emotion, double ratio})> _topEmotionRatios(
  List<_AnalysisItem> items,
) {
  final count = <String, int>{};
  for (final a in items) {
    for (final raw in a.emotions) {
      final e = _normalizeEmotion(raw);
      count[e] = (count[e] ?? 0) + 1;
    }
  }

  final total = count.values.fold<int>(0, (sum, n) => sum + n);
  final list =
      count.entries
          .map(
            (e) => (
              emotion: e.key,
              ratio: total == 0 ? 0.0 : e.value / total.toDouble(),
            ),
          )
          .toList()
        ..sort((a, b) => b.ratio.compareTo(a.ratio));
  return list.take(6).toList();
}

List<(String, int)> _topHabits(List<_AnalysisItem> items) {
  final count = <String, int>{};
  for (final a in items) {
    for (final h in a.habits) {
      final key = h.trim();
      if (key.isEmpty) continue;
      count[key] = (count[key] ?? 0) + 1;
    }
  }
  final list = count.entries.map((e) => (e.key, e.value)).toList()
    ..sort((a, b) => b.$2.compareTo(a.$2));
  return list;
}

String _summaryText(List<_AnalysisItem> items) {
  if (items.isEmpty) {
    return '이번 주에는 아직 충분한 분석 데이터가 없어요. 일기를 더 작성하면 개인화된 요약을 제공해드릴게요.';
  }
  final topEmotion = _topEmotionRatios(items).isNotEmpty
      ? _topEmotionRatios(items).first.emotion
      : '기록';
  final topHabit = _topHabits(items).isNotEmpty
      ? _topHabits(items).first.$1
      : null;
  final feedback = items.first.feedback.trim();
  final topHabitText = topHabit == null ? '' : ' 자주 보인 습관은 "$topHabit"이에요.';
  return '이번 주 대표 감정은 "$topEmotion"이에요.$topHabitText ${feedback.isEmpty ? '' : feedback}';
}

int _maxStreak(List<String> dateStrings) {
  final dates =
      dateStrings
          .map(DateTime.tryParse)
          .whereType<DateTime>()
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet()
          .toList()
        ..sort();
  if (dates.isEmpty) return 0;

  int best = 1;
  int current = 1;
  for (int i = 1; i < dates.length; i++) {
    final diff = dates[i].difference(dates[i - 1]).inDays;
    if (diff == 1) {
      current += 1;
      if (current > best) best = current;
    } else {
      current = 1;
    }
  }
  return best;
}

String _normalizeEmotion(String raw) {
  final e = raw.trim();
  if (e.contains('기쁨') ||
      e.contains('행복') ||
      e.contains('뿌듯') ||
      e.contains('신남')) {
    return '기쁨';
  }
  if (e.contains('평온') || e.contains('차분') || e.contains('안정')) return '평온';
  if (e.contains('피곤') || e.contains('지침') || e.contains('무기력')) return '피곤';
  if (e.contains('불안') || e.contains('걱정') || e.contains('초조')) return '불안';
  if (e.contains('슬픔') || e.contains('우울')) return '슬픔';
  if (e.contains('분노') || e.contains('화남') || e.contains('짜증')) return '분노';
  return e;
}

Color _emotionColor(String emotion) {
  switch (emotion) {
    case '기쁨':
      return AppColors.emotionJoy;
    case '평온':
      return AppColors.emotionCalm;
    case '피곤':
      return AppColors.emotionTired;
    case '불안':
      return AppColors.emotionAnxiety;
    case '슬픔':
      return AppColors.emotionSad;
    case '분노':
      return AppColors.emotionAnger;
    default:
      return AppColors.surfaceVariant;
  }
}
