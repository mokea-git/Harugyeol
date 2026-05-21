import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'journal_api.dart';

class JournalWriteScreen extends StatefulWidget {
  final String? journalId;
  final String? initialContent;

  const JournalWriteScreen({
    super.key,
    this.journalId,
    this.initialContent,
  });

  @override
  State<JournalWriteScreen> createState() => _JournalWriteScreenState();
}

class _JournalWriteScreenState extends State<JournalWriteScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  int _charCount = 0;
  bool _saving = false;
  String? _selectedMood;

  static const _moods = ['😊', '😌', '😢', '😤', '😰', '🥱'];

  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null) {
      _controller.text = widget.initialContent!;
      _charCount = widget.initialContent!.length;
    }
    _controller.addListener(() {
      setState(() => _charCount = _controller.text.length);
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _todayLabel {
    final now = DateTime.now();
    const months = ['1월','2월','3월','4월','5월','6월','7월','8월','9월','10월','11월','12월'];
    const weekdays = ['월요일','화요일','수요일','목요일','금요일','토요일','일요일'];
    return '${now.year}년 ${months[now.month - 1]} ${now.day}일 ${weekdays[now.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 바 ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _saving ? null : () => context.pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                    iconSize: 22,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.journalId != null ? '일기 수정' : '오늘의 일기',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _charCount > 0 ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _charCount > 0 && !_saving ? () => _showSaveDialog(context) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: _charCount > 0 ? AppColors.primary : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                '저장',
                                style: GoogleFonts.notoSansKr(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _charCount > 0 ? Colors.white : AppColors.textHint,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // ── 날짜 + 기분 선택 ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _todayLabel,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '오늘 기분은 어때요?',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 기분 선택 행
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: _moods.map((emoji) {
                        final isSelected = _selectedMood == emoji;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedMood = isSelected ? null : emoji;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: TextStyle(
                                    fontSize: isSelected ? 26 : 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: 150.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.04, end: 0),

            const SizedBox(height: 20),

            // ── 구분선 ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                color: AppColors.surfaceVariant,
                thickness: 1,
                height: 1,
              ),
            ),

            const SizedBox(height: 16),

            // ── 글쓰기 영역 ─────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 16,
                    height: 1.9,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '오늘 하루를 자유롭게 적어보세요...\n\nAI가 감정과 습관을 자동으로 분석해드려요 ✨',
                    hintStyle: GoogleFonts.notoSansKr(
                      fontSize: 16,
                      height: 1.9,
                      color: AppColors.textHint.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
              ),
            ),

            // ── 하단 정보 바 ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).padding.bottom + 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.journalId == null)
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'AI 분석 포함',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          size: 14,
                          color: AppColors.secondary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '내용 수정 중',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  Text(
                    '$_charCount자',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      color: _charCount > 0
                          ? AppColors.textSecondary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final isEditMode = widget.journalId != null;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF78BF6E), Color(0xFF4A9940)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isEditMode ? Icons.edit_rounded : Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isEditMode ? '일기를 수정할까요?' : '일기를 저장할까요?',
                style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEditMode
                    ? '내용을 업데이트합니다'
                    : 'AI가 감정과 습관을\n자동으로 분석해드려요',
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
                      onPressed: _saving
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _save();
                            },
                      child: Text(isEditMode ? '수정하기' : '저장하기'),
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

  Future<void> _save() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _saving = true);

    if (widget.journalId != null) {
      // 수정 모드: AI 재분석 없이 바로 저장
      try {
        await JournalApi.instance.updateJournal(
          id: widget.journalId!,
          content: content,
        );
        if (!mounted) return;
        context.pop(true);
      } on DioException catch (e) {
        if (!mounted) return;
        final msg = _extractError(e.response?.data) ?? '수정에 실패했어요';
        _showSnack(msg);
      } catch (_) {
        if (!mounted) return;
        _showSnack('수정에 실패했어요');
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    } else {
      // 신규 작성 모드: AI 분석 로딩 다이얼로그 표시
      _showAiLoadingDialog();
      try {
        await JournalApi.instance.createJournal(content: content, analyze: true);
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        if (!mounted) return;
        context.pop(true);
      } on DioException catch (e) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        if (!mounted) return;
        final msg = _extractError(e.response?.data) ?? '저장에 실패했어요';
        _showSnack(msg);
      } catch (_) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        if (!mounted) return;
        _showSnack('저장에 실패했어요');
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  String? _extractError(dynamic data) {
    if (data is Map && data['error'] is String) return data['error'] as String;
    return null;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.notoSansKr(fontSize: 14)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAiLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI가 분석 중이에요',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '감정과 습관을 읽고 있어요...',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
