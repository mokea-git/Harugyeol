import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────

class WeeklyEmotionReportScreen extends StatefulWidget {
  const WeeklyEmotionReportScreen({super.key});

  @override
  State<WeeklyEmotionReportScreen> createState() =>
      _WeeklyEmotionReportScreenState();
}

class _WeeklyEmotionReportScreenState
    extends State<WeeklyEmotionReportScreen> {
  bool _loading = true;
  String? _error;
  List<_Analysis> _items = const [];
  List<double>? _lastWeekScores; // null = 비교 데이터 없음

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
      // ── 이번 주 ──────────────────────────────────────
      final res = await ApiClient.instance.dio.get('/analyses/weekly');
      final raw = res.data;
      if (raw is! List) throw Exception('invalid response');
      final items = raw
          .whereType<Map>()
          .map((e) => _Analysis.fromJson(e.cast<String, dynamic>()))
          .toList();

      // ── 저번 주 (graceful fail) ───────────────────────
      List<double>? lastWeekScores;
      try {
        final now = DateTime.now();
        final lastMon = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1 + 7));
        final lastSun = lastMon.add(const Duration(days: 6));

        String fmt(DateTime d) =>
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

        final lastRes = await ApiClient.instance.dio.get(
          '/analyses/weekly',
          queryParameters: {
            'from': fmt(lastMon),
            'to': fmt(lastSun),
          },
        );
        if (lastRes.data is List) {
          final lastItems = (lastRes.data as List)
              .whereType<Map>()
              .map((e) => _Analysis.fromJson(e.cast<String, dynamic>()))
              .toList();
          if (lastItems.isNotEmpty) {
            lastWeekScores = _weeklyScores(lastItems, lastMon);
          }
        }
      } catch (_) {
        lastWeekScores = null;
      }

      if (!mounted) return;
      setState(() {
        _items = items;
        _lastWeekScores = lastWeekScores;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '감정 리포트를 불러오지 못했어요';
        _loading = false;
      });
    }
  }

  String get _weekRange {
    final now = DateTime.now();
    final mon = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final sun = mon.add(const Duration(days: 6));
    return '${mon.month}월 ${mon.day}일 – ${sun.month}월 ${sun.day}일';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final summary = _error == null ? _Summary.fromItems(_items) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── AppBar (투명/베이지) ─────────────────────
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              title: Text(
                'AI 주간 감정 분석',
                style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // ── Content ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                child: _error != null
                    ? _buildError()
                    : _buildContent(summary!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────
  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😢', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.notoSansKr(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  // ── Full content ───────────────────────────────────────
  Widget _buildContent(_Summary summary) {
    final isEmpty = _items.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 범위 필
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _weekRange,
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // AI 리포트 (항상 표시)
        _AiReportCard(items: _items),
        const SizedBox(height: 20),

        if (isEmpty)
          _buildEmpty()
        else ...[
          // 대표 감정
          _TopSummaryCard(summary: summary),
          const SizedBox(height: 20),

          // 감정 흐름 (이번 주 + 저번 주 비교)
          const _SectionTitle(text: '하루별 감정 흐름'),
          const SizedBox(height: 10),
          _FlowCard(
            thisWeekScores: summary.weeklyScores,
            lastWeekScores: _lastWeekScores,
          ),
          const SizedBox(height: 20),

          // 감정 비율
          const _SectionTitle(text: '이번 주 감정 비율'),
          const SizedBox(height: 10),
          if (summary.ratios.isEmpty)
            const _NoDataTile()
          else
            _EmotionChips(ratios: summary.ratios),
          const SizedBox(height: 20),

          // 일자별 요약
          const _SectionTitle(text: '일자별 요약'),
          const SizedBox(height: 10),
          ..._items.asMap().entries.map(
            (e) => _DayTile(index: e.key, item: e.value),
          ),
        ],
      ],
    );
  }

  // ── Empty state ────────────────────────────────────────
  Widget _buildEmpty() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🌱', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '아직 이번 주 일기가 없어요',
                style: GoogleFonts.notoSansKr(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '일기를 쓰면 AI가 자동으로\n감정을 분석해 드려요 ✨',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 플레이스홀더 차트
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '하루별 감정 흐름',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in [
                    ('월', 52.0),
                    ('화', 66.0),
                    ('수', 48.0),
                    ('목', 78.0),
                    ('금', 58.0),
                    ('토', 62.0),
                    ('일', 44.0),
                  ])
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: d.$2,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d.$1,
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
              Center(
                child: Text(
                  '📈  일기를 쓰면 감정 흐름이 나타나요',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────

class _Analysis {
  final String journalId;
  final List<String> emotions;
  final String feedback;
  final String? summary;
  final DateTime createdAt;

  const _Analysis({
    required this.journalId,
    required this.emotions,
    required this.feedback,
    required this.summary,
    required this.createdAt,
  });

  factory _Analysis.fromJson(Map<String, dynamic> json) {
    return _Analysis(
      journalId: (json['journal_id'] as String?) ?? '',
      emotions: (json['emotions'] is List)
          ? (json['emotions'] as List).whereType<String>().toList()
          : const <String>[],
      feedback: (json['feedback'] as String?) ?? '',
      summary: json['summary'] as String?,
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

class _Summary {
  final String topEmotion;
  final List<({String emotion, double ratio})> ratios;
  final List<double> weeklyScores;

  const _Summary({
    required this.topEmotion,
    required this.ratios,
    required this.weeklyScores,
  });

  factory _Summary.fromItems(List<_Analysis> items) {
    final count = <String, int>{};
    for (final item in items) {
      for (final raw in item.emotions) {
        final e = _normalize(raw);
        count[e] = (count[e] ?? 0) + 1;
      }
    }

    final total = count.values.fold<int>(0, (sum, n) => sum + n);
    final ratios =
        count.entries
            .map(
              (e) => (
                emotion: e.key,
                ratio: total == 0 ? 0.0 : e.value / total.toDouble(),
              ),
            )
            .toList()
          ..sort((a, b) => b.ratio.compareTo(a.ratio));

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final scores = _weeklyScores(items, monday);

    return _Summary(
      topEmotion: ratios.isEmpty ? '데이터 없음' : ratios.first.emotion,
      ratios: ratios.take(6).toList(),
      weeklyScores: scores,
    );
  }
}

// ─────────────────────────────────────────────────────────
// UI Widgets
// ─────────────────────────────────────────────────────────

// AI 리포트 카드
class _AiReportCard extends StatelessWidget {
  final List<_Analysis> items;
  const _AiReportCard({required this.items});

  String get _reportText {
    if (items.isEmpty) {
      return '이번 주에는 아직 일기 데이터가 없어요.\n꾸준히 일기를 작성하면 개인화된 AI 리포트를 받을 수 있어요 📝';
    }

    final count = <String, int>{};
    for (final item in items) {
      for (final raw in item.emotions) {
        final e = _normalize(raw);
        count[e] = (count[e] ?? 0) + 1;
      }
    }
    final sorted = count.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEmotion = sorted.isEmpty ? null : sorted.first.key;
    final secondEmotion = sorted.length >= 2 ? sorted[1].key : null;

    final feedbackSrc =
        items.where((e) => e.feedback.trim().length > 10).toList();
    final feedback =
        feedbackSrc.isEmpty ? null : feedbackSrc.first.feedback.trim();

    final topText = topEmotion == null ? '다양한 감정' : '"$topEmotion"';
    final secondText =
        secondEmotion != null ? ' 그 뒤로는 "$secondEmotion"도 자주 느꼈어요.' : '';
    final feedbackText =
        feedback ??
        '일기를 통해 자신의 감정을 꾸준히 돌아보는 모습이 정말 멋져요 💚';

    return '이번 주 대표 감정은 $topText이에요.$secondText $feedbackText';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A34), Color(0xFF2D5244)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                'AI 주간 리포트',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _reportText,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              height: 1.7,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// 섹션 타이틀
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
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
          text,
          style: GoogleFonts.notoSansKr(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// 빈 데이터 타일
class _NoDataTile extends StatelessWidget {
  const _NoDataTile();

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
        '이번 주 분석 데이터가 없어요',
        style: GoogleFonts.notoSansKr(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// 대표 감정 카드
class _TopSummaryCard extends StatelessWidget {
  final _Summary summary;
  const _TopSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final ec = _paletteColor(summary.topEmotion);
    final pct = summary.ratios.isNotEmpty
        ? (summary.ratios.first.ratio * 100).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ec.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ec.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ec.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _emoji(summary.topEmotion),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  summary.topEmotion,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$pct% 비율로 가장 많이 느꼈어요',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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

// 감정 흐름 차트 카드 (이번 주 + 저번 주 비교)
class _FlowCard extends StatelessWidget {
  final List<double> thisWeekScores;
  final List<double>? lastWeekScores;
  const _FlowCard({
    required this.thisWeekScores,
    this.lastWeekScores,
  });

  @override
  Widget build(BuildContext context) {
    final hasLast = lastWeekScores != null;

    return Container(
      height: hasLast ? 230 : 210,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 범례
          if (hasLast)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LegendItem(
                    color: AppColors.primary,
                    label: '이번 주',
                    dashed: false,
                  ),
                  const SizedBox(width: 14),
                  _LegendItem(
                    color: const Color(0xFFB0BEC5),
                    label: '지난 주',
                    dashed: true,
                  ),
                ],
              ),
            ),
          // 차트
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y축
                SizedBox(
                  width: 28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '좋음',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 9,
                          color: AppColors.textHint,
                        ),
                      ),
                      Text(
                        '보통',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 9,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: SizedBox.expand(
                    child: CustomPaint(
                      painter: _FlowPainter(
                        thisWeek: thisWeekScores,
                        lastWeek: lastWeekScores,
                      ),
                    ),
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

// 범례 아이템
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendItem({
    required this.color,
    required this.label,
    required this.dashed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!dashed)
          Container(
            width: 18,
            height: 2.5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          Row(
            children: [
              Container(width: 7, height: 2, color: color),
              const SizedBox(width: 2),
              Container(width: 4, height: 2, color: color),
              const SizedBox(width: 2),
              Container(width: 3, height: 2, color: color),
            ],
          ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 10,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

// 차트 페인터
class _FlowPainter extends CustomPainter {
  final List<double> thisWeek;
  final List<double>? lastWeek;
  _FlowPainter({required this.thisWeek, this.lastWeek});

  @override
  void paint(Canvas canvas, Size size) {
    final thisValues =
        thisWeek.length == 7 ? thisWeek : List<double>.filled(7, 0.5);
    const labelH = 20.0;
    final chartH = size.height - labelH;
    final days = const ['월', '화', '수', '목', '금', '토', '일'];

    // 그리드
    final gridPaint = Paint()
      ..color = const Color(0xFFF0EFEB)
      ..strokeWidth = 1;
    for (final f in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      canvas.drawLine(
        Offset(0, chartH * f),
        Offset(size.width, chartH * f),
        gridPaint,
      );
    }

    // ── 저번 주 (점선, 회색) ──────────────────────────
    if (lastWeek != null && lastWeek!.length == 7) {
      final lv = lastWeek!;
      final lastPath = Path();
      for (int i = 0; i < lv.length; i++) {
        final x = size.width * i / 6;
        final y = chartH * (1 - lv[i]);
        if (i == 0) {
          lastPath.moveTo(x, y);
        } else {
          final px = size.width * (i - 1) / 6;
          final py = chartH * (1 - lv[i - 1]);
          final cx = px + (x - px) / 2;
          lastPath.cubicTo(cx, py, cx, y, x, y);
        }
      }
      _drawDashed(
        canvas,
        lastPath,
        Paint()
          ..color = const Color(0xFFB0BEC5)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      // 저번 주 점
      for (int i = 0; i < lv.length; i++) {
        canvas.drawCircle(
          Offset(size.width * i / 6, chartH * (1 - lv[i])),
          3,
          Paint()..color = const Color(0xFFB0BEC5),
        );
      }
    }

    // ── 이번 주 채우기 + 선 ────────────────────────────
    final fillPath = Path();
    final thisPath = Path();
    for (int i = 0; i < thisValues.length; i++) {
      final x = size.width * i / 6;
      final y = chartH * (1 - thisValues[i]);
      if (i == 0) {
        thisPath.moveTo(x, y);
        fillPath.moveTo(x, chartH);
        fillPath.lineTo(x, y);
      } else {
        final px = size.width * (i - 1) / 6;
        final py = chartH * (1 - thisValues[i - 1]);
        final cx = px + (x - px) / 2;
        thisPath.cubicTo(cx, py, cx, y, x, y);
        fillPath.cubicTo(cx, py, cx, y, x, y);
      }
    }
    fillPath.lineTo(size.width, chartH);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
    );

    canvas.drawPath(
      thisPath,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 이번 주 점 + 요일 라벨
    for (int i = 0; i < thisValues.length; i++) {
      final x = size.width * i / 6;
      final y = chartH * (1 - thisValues[i]);

      canvas.drawCircle(Offset(x, y), 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(x, y),
        5.5,
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );

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

  // 점선 그리기
  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dashLen = 7.0;
    const gapLen = 5.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0.0;
      bool draw = true;
      while (dist < metric.length) {
        final segLen = draw ? dashLen : gapLen;
        final end = (dist + segLen).clamp(0.0, metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(dist, end), paint);
        }
        dist = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlowPainter old) =>
      old.thisWeek != thisWeek || old.lastWeek != lastWeek;
}

// 감정 비율 칩
class _EmotionChips extends StatelessWidget {
  final List<({String emotion, double ratio})> ratios;
  const _EmotionChips({required this.ratios});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ratios.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _paletteColor(e.emotion),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_emoji(e.emotion), style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                e.emotion,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${(e.ratio * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// 일자별 요약 타일
class _DayTile extends StatelessWidget {
  final int index;
  final _Analysis item;
  const _DayTile({required this.index, required this.item});

  static const _weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final top =
        item.emotions.isEmpty ? '기록됨' : _normalize(item.emotions.first);
    final text =
        item.summary?.trim().isNotEmpty == true
            ? item.summary!.trim()
            : item.feedback;
    final wd = _weekdays[item.createdAt.weekday];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 좌측 감정 컬러 바
              Container(width: 5, color: _accentColor(top)),
              // 이모지 뱃지
              Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _paletteColor(top),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _emoji(top),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
              // 텍스트
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${item.createdAt.month}월 ${item.createdAt.day}일',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              wd,
                              style: GoogleFonts.notoSansKr(
                                fontSize: 10,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
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
}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

// 주간 점수 계산 (재사용 가능)
List<double> _weeklyScores(List<_Analysis> items, DateTime monday) {
  final scores = List<double>.filled(7, 0.5);
  for (int i = 0; i < 7; i++) {
    final day = monday.add(Duration(days: i));
    final dayItems = items.where((item) {
      final d = item.createdAt.toLocal();
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
    if (dayItems.isEmpty) {
      scores[i] = 0.5;
      continue;
    }
    var sum = 0.0;
    var n = 0;
    for (final item in dayItems) {
      for (final emotion in item.emotions) {
        sum += _score(_normalize(emotion));
        n += 1;
      }
    }
    scores[i] = n == 0 ? 0.5 : (sum / n).clamp(0.0, 1.0);
  }
  return scores;
}

String _normalize(String raw) {
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

String _emoji(String emotion) {
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

Color _paletteColor(String emotion) {
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

Color _accentColor(String emotion) {
  switch (emotion) {
    case '기쁨':
      return const Color(0xFFFFB300);
    case '평온':
      return const Color(0xFF66BB6A);
    case '피곤':
      return const Color(0xFF90A4AE);
    case '불안':
      return const Color(0xFFAB47BC);
    case '슬픔':
      return const Color(0xFF42A5F5);
    case '분노':
      return const Color(0xFFEF5350);
    default:
      return AppColors.primary;
  }
}

double _score(String emotion) {
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
