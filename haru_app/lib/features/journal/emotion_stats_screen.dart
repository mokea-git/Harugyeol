import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';

class EmotionStatsScreen extends StatefulWidget {
  const EmotionStatsScreen({super.key});

  @override
  State<EmotionStatsScreen> createState() => _EmotionStatsScreenState();
}

class _EmotionStatsScreenState extends State<EmotionStatsScreen> {
  bool _loading = true;
  String? _error;
  List<_AnalysisEntry> _entries = const [];

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
      final res = await ApiClient.instance.dio.get('/analyses/weekly');
      final raw = res.data;
      if (raw is! List) {
        throw Exception('Invalid response');
      }

      final entries =
          raw
              .whereType<Map>()
              .map((e) => _AnalysisEntry.fromJson(e.cast<String, dynamic>()))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '감정 데이터를 불러오지 못했어요';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _EmotionSummary.fromEntries(_entries);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorView(message: _error!, onRetry: _load)
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    backgroundColor: AppColors.background,
                    leading: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      '감정 통계',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopEmotionCard(summary: summary),
                          const SizedBox(height: 24),
                          Text(
                            '감정 흐름',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _LineChartCard(points: summary.weeklyScores),
                          const SizedBox(height: 24),
                          Text(
                            '감정 비율',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _EmotionBarCard(ratios: summary.sortedRatios),
                          const SizedBox(height: 24),
                          Text(
                            '최근 일기 분석',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          if (_entries.isEmpty)
                            _EmptyJournalCard()
                          else
                            ..._entries
                                .take(6)
                                .map((e) => _JournalTile(entry: e)),
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

class _AnalysisEntry {
  final String journalId;
  final List<String> emotions;
  final String feedback;
  final String? summary;
  final DateTime createdAt;

  const _AnalysisEntry({
    required this.journalId,
    required this.emotions,
    required this.feedback,
    required this.summary,
    required this.createdAt,
  });

  factory _AnalysisEntry.fromJson(Map<String, dynamic> json) {
    final emotionsRaw = json['emotions'];
    final emotions = emotionsRaw is List
        ? emotionsRaw.whereType<String>().toList()
        : const <String>[];

    return _AnalysisEntry(
      journalId: (json['journal_id'] as String?) ?? '',
      emotions: emotions,
      feedback: (json['feedback'] as String?) ?? '',
      summary: json['summary'] as String?,
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

class _EmotionSummary {
  final String topEmotion;
  final List<({String emotion, double ratio, Color color})> sortedRatios;
  final List<double> weeklyScores;

  const _EmotionSummary({
    required this.topEmotion,
    required this.sortedRatios,
    required this.weeklyScores,
  });

  factory _EmotionSummary.fromEntries(List<_AnalysisEntry> entries) {
    final counter = <String, int>{};
    for (final e in entries) {
      for (final raw in e.emotions) {
        final normalized = _normalizeEmotion(raw);
        counter[normalized] = (counter[normalized] ?? 0) + 1;
      }
    }

    final total = counter.values.fold<int>(0, (a, b) => a + b);
    final ratios =
        counter.entries
            .map(
              (e) => (
                emotion: e.key,
                ratio: total == 0 ? 0.0 : e.value / total.toDouble(),
                color: _emotionColor(e.key),
              ),
            )
            .toList()
          ..sort((a, b) => b.ratio.compareTo(a.ratio));

    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final scores = List<double>.filled(7, 0.5);

    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final dayEntries = entries.where((e) {
        final d = e.createdAt.toLocal();
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).toList();

      if (dayEntries.isEmpty) {
        scores[i] = 0.5;
        continue;
      }

      var sum = 0.0;
      var count = 0;
      for (final entry in dayEntries) {
        for (final raw in entry.emotions) {
          sum += _emotionScore(_normalizeEmotion(raw));
          count += 1;
        }
      }
      scores[i] = count == 0 ? 0.5 : (sum / count).clamp(0.0, 1.0);
    }

    return _EmotionSummary(
      topEmotion: ratios.isEmpty ? '데이터 없음' : ratios.first.emotion,
      sortedRatios: ratios,
      weeklyScores: scores,
    );
  }
}

class _TopEmotionCard extends StatelessWidget {
  final _EmotionSummary summary;
  const _TopEmotionCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            _emotionEmoji(summary.topEmotion),
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이번 주 대표 감정',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary.topEmotion,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
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

class _LineChartCard extends StatelessWidget {
  final List<double> points;
  const _LineChartCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 170),
        painter: _FlowPainter(points: points),
      ),
    );
  }
}

class _FlowPainter extends CustomPainter {
  final List<double> points;
  _FlowPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final days = const ['월', '화', '수', '목', '금', '토', '일'];
    final values = points.length == 7 ? points : List<double>.filled(7, 0.5);
    final chartHeight = size.height - 24;

    final gridPaint = Paint()
      ..color = AppColors.surfaceVariant
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.2),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));

    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / 6;
      final y = chartHeight * (1 - values[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
      } else {
        final prevX = size.width * (i - 1) / 6;
        final prevY = chartHeight * (1 - values[i - 1]);
        final c = prevX + (x - prevX) / 2;
        path.cubicTo(c, prevY, c, y, x, y);
        fillPath.cubicTo(c, prevY, c, y, x, y);
      }
    }
    fillPath.lineTo(size.width, chartHeight);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / 6;
      final y = chartHeight * (1 - values[i]);
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = AppColors.primary);

      final tp = TextPainter(
        text: TextSpan(
          text: days[i],
          style: GoogleFonts.notoSansKr(
            fontSize: 11,
            color: AppColors.textHint,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant _FlowPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) return true;
    for (int i = 0; i < points.length; i++) {
      if ((oldDelegate.points[i] - points[i]).abs() > 0.0001) return true;
    }
    return false;
  }
}

class _EmotionBarCard extends StatelessWidget {
  final List<({String emotion, double ratio, Color color})> ratios;
  const _EmotionBarCard({required this.ratios});

  @override
  Widget build(BuildContext context) {
    final items = ratios.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: items.isEmpty
          ? Text(
              '아직 감정 분석 데이터가 없어요',
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 42,
                        child: Text(
                          item.emotion,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: max(0.04, item.ratio),
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 38,
                        child: Text(
                          '${(item.ratio * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
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

class _JournalTile extends StatelessWidget {
  final _AnalysisEntry entry;
  const _JournalTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final topEmotion = entry.emotions.isEmpty
        ? '기록됨'
        : _normalizeEmotion(entry.emotions.first);
    final title = entry.summary?.trim().isNotEmpty == true
        ? entry.summary!.trim()
        : entry.feedback;
    final date = '${entry.createdAt.month}/${entry.createdAt.day}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _emotionColor(topEmotion).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(_emotionEmoji(topEmotion))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _EmptyJournalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '아직 분석된 일기가 없어요. 일기를 작성해보세요.',
        style: GoogleFonts.notoSansKr(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
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
  return e.isEmpty ? '기록됨' : e;
}

double _emotionScore(String emotion) {
  switch (emotion) {
    case '기쁨':
      return 0.95;
    case '평온':
      return 0.8;
    case '피곤':
      return 0.45;
    case '불안':
      return 0.3;
    case '슬픔':
      return 0.25;
    case '분노':
      return 0.2;
    default:
      return 0.5;
  }
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
      return AppColors.primarySurface;
  }
}

String _emotionEmoji(String emotion) {
  switch (emotion) {
    case '기쁨':
      return '😊';
    case '평온':
      return '😌';
    case '피곤':
      return '🥱';
    case '불안':
      return '😰';
    case '슬픔':
      return '😢';
    case '분노':
      return '😤';
    default:
      return '📝';
  }
}
