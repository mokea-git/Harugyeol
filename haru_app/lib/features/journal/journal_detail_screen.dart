import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'journal_api.dart';

class JournalDetailScreen extends StatefulWidget {
  final String journalId;
  const JournalDetailScreen({super.key, required this.journalId});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  JournalEntry? _journal;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final journal = await JournalApi.instance.getJournal(widget.journalId);
      if (!mounted) return;
      setState(() { _journal = journal; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = '일기를 불러오지 못했어요'; _loading = false; });
    }
  }

  void _showDeleteDialog(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE57373),
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '일기를 삭제할까요?',
                style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '삭제된 일기는 복구할 수 없어요',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE57373),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await JournalApi.instance.deleteJournal(
                            widget.journalId,
                          );
                          if (mounted) router.pop(true);
                        } catch (_) {
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '삭제에 실패했어요',
                                  style: GoogleFonts.notoSansKr(fontSize: 14),
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('삭제'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _journal == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? '데이터를 찾을 수 없어요'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    final journal = _journal!;
    final analysis = journal.analysis;
    final emotions = analysis?.emotions ?? const <String>[];
    final habits = analysis?.habits ?? const <String>[];
    final emoji = _journalEmoji(journal);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      body: CustomScrollView(
        slivers: [
          // ── 헤더 ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.dark,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            actions: [
              // 수정 버튼
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () async {
                    final result = await context.push(
                      '/journal/write',
                      extra: {
                        'journalId': journal.id,
                        'initialContent': journal.content,
                      },
                    );
                    if (result == true && mounted) _load();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // 삭제 버튼
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _showDeleteDialog(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A34), Color(0xFF2D5244), Color(0xFF3A6B54)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(journal.date),
                                    style: GoogleFonts.notoSansKr(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    emotions.isNotEmpty
                                        ? _normalizeEmotion(emotions.first)
                                        : '하루 기록',
                                    style: GoogleFonts.notoSansKr(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(emoji, style: const TextStyle(fontSize: 48)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 본문 ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 일기 내용
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      journal.content,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 16,
                        height: 1.9,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04, end: 0),

                  const SizedBox(height: 20),

                  // AI 분석 카드
                  if (analysis != null) ...[
                    _AiAnalysisCard(
                      emotions: emotions,
                      habits: habits,
                      feedback: analysis.feedback,
                    ).animate(delay: 200.ms).fadeIn(duration: 600.ms).slideY(begin: 0.04, end: 0),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI 분석 카드 ───────────────────────────────────────────────────────────────

class _AiAnalysisCard extends StatelessWidget {
  final List<String> emotions;
  final List<String> habits;
  final String feedback;

  const _AiAnalysisCard({
    required this.emotions,
    required this.habits,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF2FAF1), Color(0xFFE8F3E6)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'AI 분석 결과',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: AppColors.primary.withValues(alpha: 0.1),
            height: 1,
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 감정
                if (emotions.isNotEmpty) ...[
                  _SectionLabel('감지된 감정'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emotions.take(4).map((e) {
                      final norm = _normalizeEmotion(e);
                      return _EmotionChip(label: norm, color: _emotionColor(norm));
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // 습관
                if (habits.isNotEmpty) ...[
                  _SectionLabel('감지된 습관'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: habits.take(4).map((h) => _HabitChip(label: h)).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // AI 피드백
                if (feedback.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF283F3B), Color(0xFF4A7A52)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.eco_rounded, size: 16, color: Color(0xFF8BBF84)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feedback,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 14,
                              height: 1.6,
                              color: AppColors.dark,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSansKr(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _EmotionChip extends StatelessWidget {
  final String label;
  final Color color;
  const _EmotionChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
      ),
    );
  }
}

class _HabitChip extends StatelessWidget {
  final String label;
  const _HabitChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}

// ── 유틸 함수 ─────────────────────────────────────────────────────────────────

String _formatDate(String isoDate) {
  final dt = DateTime.tryParse(isoDate);
  if (dt == null) return isoDate;
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${dt.year}년 ${dt.month}월 ${dt.day}일 ${weekdays[dt.weekday - 1]}요일';
}

String _normalizeEmotion(String raw) {
  final e = raw.trim();
  if (e.contains('기쁨') || e.contains('행복') || e.contains('뿌듯') || e.contains('신남')) return '기쁨';
  if (e.contains('평온') || e.contains('차분') || e.contains('안정')) return '평온';
  if (e.contains('피곤') || e.contains('지침') || e.contains('무기력')) return '피곤';
  if (e.contains('불안') || e.contains('걱정') || e.contains('초조')) return '불안';
  if (e.contains('슬픔') || e.contains('우울')) return '슬픔';
  if (e.contains('분노') || e.contains('화남') || e.contains('짜증')) return '분노';
  return e;
}

String _journalEmoji(JournalEntry journal) {
  final emotion = journal.analysis?.emotions.isNotEmpty == true
      ? _normalizeEmotion(journal.analysis!.emotions.first)
      : '';
  switch (emotion) {
    case '기쁨': return '😊';
    case '평온': return '😌';
    case '슬픔': return '😢';
    case '분노': return '😤';
    case '불안': return '😰';
    case '피곤': return '🥱';
    default:    return '📝';
  }
}

Color _emotionColor(String emotion) {
  switch (emotion) {
    case '기쁨': return AppColors.emotionJoy;
    case '평온': return AppColors.emotionCalm;
    case '피곤': return AppColors.emotionTired;
    case '불안': return AppColors.emotionAnxiety;
    case '슬픔': return AppColors.emotionSad;
    case '분노': return AppColors.emotionAnger;
    default:    return AppColors.surfaceVariant;
  }
}
