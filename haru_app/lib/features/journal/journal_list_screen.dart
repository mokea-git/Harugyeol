import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ads/ad_service.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_colors.dart';
import '../auth/profile_service.dart';
import '../subscription/subscription_api.dart';
import 'journal_api.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  UserProfile? _profile;
  List<JournalEntry> _journals = const [];
  bool _loading = true;
  String? _error;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadJournals();
    _loadSubscriptionStatus();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.instance.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (_) {}
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final status = await SubscriptionApi.instance.getStatus();
      if (mounted) setState(() => _isPro = status.isPro);
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
        _error = '일기 목록을 불러오지 못했어요';
        _loading = false;
      });
    }
  }

  String get _todayLabel {
    final now = DateTime.now();
    const months = [
      '1월',
      '2월',
      '3월',
      '4월',
      '5월',
      '6월',
      '7월',
      '8월',
      '9월',
      '10월',
      '11월',
      '12월',
    ];
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return '${months[now.month - 1]} ${now.day}일 ${weekdays[now.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _profile?.nickname ?? '';
    final greeting = nickname.isNotEmpty ? '안녕하세요,\n$nickname님 👋' : '오늘의 하루결';

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadJournals,
        edgeOffset: 120,
        child: CustomScrollView(
          slivers: [
            // ── 그라디언트 헤더 ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _todayLabel,
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  greeting,
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => context.push('/settings'),
                              child: _HomeAvatar(profile: _profile),
                            ),
                          ],
                        ).animate().fadeIn(duration: 500.ms),

                        const SizedBox(height: 22),

                        // 이번 주 감정 카드 (헤더 내부)
                        GestureDetector(
                          onTap: () => context.push('/emotion-stats'),
                          child: _WeeklyMoodCard(journals: _journals),
                        ).animate(delay: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.04, end: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── 배너 + 퀵액션 + 리스트 ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WeeklyEmotionBanner()
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.04, end: 0),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        _QuickAction(
                          icon: Icons.bar_chart_rounded,
                          label: '감정 통계',
                          color: const Color(0xFF5B8DEF),
                          onTap: () => context.push('/emotion-stats'),
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.article_outlined,
                          label: '주간 리포트',
                          color: const Color(0xFF9B7FDB),
                          onTap: () => context.push('/report'),
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.workspace_premium_rounded,
                          label: 'PRO',
                          color: const Color(0xFFFFAB00),
                          onTap: () => context.push('/pro'),
                        ),
                      ],
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    Text(
                      '최근 기록',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ).animate(delay: 350.ms).fadeIn(duration: 400.ms),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _error!,
                              style: GoogleFonts.notoSansKr(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadJournals,
                            child: const Text('재시도'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_journals.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text('📝', style: const TextStyle(fontSize: 40)),
                          const SizedBox(height: 14),
                          Text(
                            '첫 번째 기록을 남겨보세요',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'AI가 감정과 습관을 자동으로\n분석해드려요',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Pro가 아닐 때 3번째 일기마다 광고 삽입
                        // 아이템 순서: 일기 일기 일기 광고 일기 일기 일기 광고 ...
                        if (!_isPro) {
                          // 4개 단위 (일기 3 + 광고 1) 반복
                          final groupIndex = index % 4;
                          final journalIndex = (index ~/ 4) * 3 + groupIndex;
                          if (groupIndex == 3) {
                            // 광고 슬롯 (3번째마다)
                            if (journalIndex <= _journals.length) {
                              return const JournalBannerAd();
                            }
                            return null;
                          }
                          if (journalIndex >= _journals.length) return null;
                          final journal = _journals[journalIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: ValueKey(journal.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEEEE),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFE57373),
                                  size: 26,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                bool? confirmed = false;
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
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
                                              borderRadius:
                                                  BorderRadius.circular(18),
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
                                                  onPressed: () {
                                                    confirmed = false;
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text('취소'),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFE57373),
                                                  ),
                                                  onPressed: () {
                                                    confirmed = true;
                                                    Navigator.pop(ctx);
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
                                return confirmed;
                              },
                              onDismissed: (_) async {
                                try {
                                  await JournalApi.instance
                                      .deleteJournal(journal.id);
                                  setState(() => _journals
                                      .removeWhere((j) => j.id == journal.id));
                                } catch (_) {
                                  _loadJournals();
                                }
                              },
                              child: GestureDetector(
                                onTap: () async {
                                  final result = await context
                                      .push('/journal/${journal.id}');
                                  if (result == true) _loadJournals();
                                },
                                onLongPress: () async {
                                  final result = await context.push(
                                    '/journal/write',
                                    extra: {
                                      'journalId': journal.id,
                                      'initialContent': journal.content,
                                    },
                                  );
                                  if (result == true) _loadJournals();
                                },
                                child: _JournalCard(journal: journal)
                                    .animate(
                                        delay: Duration(
                                            milliseconds: 80 * journalIndex))
                                    .fadeIn(duration: 350.ms)
                                    .slideY(begin: 0.04, end: 0),
                              ),
                            ),
                          );
                        }
                        // Pro 유저: 광고 없이 일반 목록
                        final journal = _journals[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey(journal.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEEEE),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFE57373),
                                size: 26,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              bool? confirmed = false;
                              await showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
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
                                            borderRadius:
                                                BorderRadius.circular(18),
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
                                                onPressed: () {
                                                  confirmed = false;
                                                  Navigator.pop(ctx);
                                                },
                                                child: const Text('취소'),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                style:
                                                    ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFFE57373),
                                                ),
                                                onPressed: () {
                                                  confirmed = true;
                                                  Navigator.pop(ctx);
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
                              return confirmed;
                            },
                            onDismissed: (_) async {
                              try {
                                await JournalApi.instance
                                    .deleteJournal(journal.id);
                                setState(() => _journals
                                    .removeWhere((j) => j.id == journal.id));
                              } catch (_) {
                                _loadJournals();
                              }
                            },
                            child: GestureDetector(
                              onTap: () async {
                                final result = await context
                                    .push('/journal/${journal.id}');
                                if (result == true) _loadJournals();
                              },
                              onLongPress: () async {
                                final result = await context.push(
                                  '/journal/write',
                                  extra: {
                                    'journalId': journal.id,
                                    'initialContent': journal.content,
                                  },
                                );
                                if (result == true) _loadJournals();
                              },
                              child: _JournalCard(journal: journal)
                                  .animate(
                                      delay: Duration(
                                          milliseconds: 80 * index))
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.04, end: 0),
                            ),
                          ),
                        );
                      },
                      childCount: _isPro
                          ? _journals.length
                          : (_journals.length + (_journals.length ~/ 3)),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await context.push('/journal/write');
            if (result == true) _loadJournals();
          },
          backgroundColor: AppColors.dark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: Text(
            '일기쓰기',
            style: GoogleFonts.notoSansKr(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ).animate().scale(
        delay: 500.ms,
        duration: 400.ms,
        curve: Curves.easeOutBack,
      ),
    );
  }
}

class _WeeklyEmotionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/weekly-emotion-report'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9B7FDB), Color(0xFF7B5FB5)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9B7FDB).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '저번 주 감정 분석',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AI가 한 주를 읽어드렸어요',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyMoodCard extends StatelessWidget {
  final List<JournalEntry> journals;
  const _WeeklyMoodCard({required this.journals});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final dates = List.generate(7, (i) => monday.add(Duration(days: i)));
    final days = const ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '이번 주 감정',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${now.month}월 ${((now.day - 1) ~/ 7) + 1}주',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(7, (i) {
              final date = dates[i];
              final key = _dateKey(date);
              final journal = journals
                  .where((j) => j.date == key)
                  .cast<JournalEntry?>()
                  .firstWhere((j) => j != null, orElse: () => null);
              final emoji = _journalEmoji(journal);
              final isToday = i == now.weekday - 1;
              final hasMood = emoji.isNotEmpty;

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      days[i],
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        color: isToday
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.white.withValues(alpha: 0.25)
                            : hasMood
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: hasMood
                            ? Text(emoji, style: const TextStyle(fontSize: 19))
                            : isToday
                            ? Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.8),
                              )
                            : Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry journal;
  const _JournalCard({required this.journal});

  @override
  Widget build(BuildContext context) {
    final emotions = journal.analysis?.emotions ?? const <String>[];
    final primaryEmotion = emotions.isNotEmpty ? _normalizeEmotion(emotions.first) : '';
    final accentColor = primaryEmotion.isNotEmpty
        ? _emotionColor(primaryEmotion)
        : AppColors.primarySurface;
    final emoji = _journalEmoji(journal);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
          child: Row(
            children: [
              // 감정 컬러 좌측 바
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(journal.date),
                            style: GoogleFonts.notoSansKr(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        journal.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 15,
                          height: 1.55,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (emotions.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: emotions.take(3).map((e) {
                            final norm = _normalizeEmotion(e);
                            final c = _emotionColor(norm);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: c.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                norm,
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dark,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeAvatar extends StatelessWidget {
  final UserProfile? profile;
  const _HomeAvatar({this.profile});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl;
    final initial = profile?.initial ?? '하';
    final bytes = _dataUriBytes(avatarUrl);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _InitialIcon(initial: initial, onDark: true),
            )
          : avatarUrl != null && avatarUrl.isNotEmpty
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _InitialIcon(initial: initial, onDark: true),
            )
          : _InitialIcon(initial: initial, onDark: true),
    );
  }

  Uint8List? _dataUriBytes(String? value) {
    if (value == null || !value.startsWith('data:image')) return null;
    final commaIndex = value.indexOf(',');
    if (commaIndex < 0) return null;
    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }
}

class _InitialIcon extends StatelessWidget {
  final String initial;
  final bool onDark;
  const _InitialIcon({required this.initial, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.notoSansKr(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onDark ? Colors.white.withValues(alpha: 0.9) : AppColors.primary,
        ),
      ),
    );
  }
}

String _dateKey(DateTime date) {
  final y = date.year;
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _formatDate(String isoDate) {
  final dt = DateTime.tryParse(isoDate);
  if (dt == null) return isoDate;
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${dt.month}월 ${dt.day}일 ${weekdays[dt.weekday - 1]}요일';
}

String _journalEmoji(JournalEntry? journal) {
  if (journal == null) return '';
  final emotion = journal.analysis?.emotions.isNotEmpty == true
      ? _normalizeEmotion(journal.analysis!.emotions.first)
      : '';
  switch (emotion) {
    case '기쁨':
      return '😊';
    case '평온':
      return '😌';
    case '슬픔':
      return '😢';
    case '분노':
      return '😤';
    case '불안':
      return '😰';
    case '피곤':
      return '🥱';
    default:
      return '';
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
