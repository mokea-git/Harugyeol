import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'coach_api.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  bool _hasText = false;
  bool _loadingHistory = true;
  bool _sending = false;
  String? _historyError;
  List<CoachMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final history = await CoachApi.instance.getHistory();
      if (!mounted) return;
      setState(() {
        _messages = history;
        _loadingHistory = false;
      });
      _jumpToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _historyError = '대화를 불러오지 못했어요';
        _loadingHistory = false;
      });
    }
  }

  void _jumpToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;

    final userMessage = CoachMessage(
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages = [..._messages, userMessage];
      _sending = true;
    });
    _controller.clear();
    _jumpToBottom(animated: true);

    try {
      final reply = await CoachApi.instance.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages = [
          ..._messages,
          CoachMessage(
            role: 'assistant',
            content: reply,
            createdAt: DateTime.now(),
          ),
        ];
        _sending = false;
      });
      _jumpToBottom(animated: true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final status = e.response?.statusCode;
      _showError(
        status == 401
            ? '로그인이 만료됐어요. 다시 로그인해 주세요'
            : '메시지 전송에 실패했어요',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      _showError('메시지 전송에 실패했어요');
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '대화를 모두 지울까요?',
                style: GoogleFonts.notoSansKr(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '지운 대화는 복구할 수 없어요',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: const Text('지우기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true || !mounted) return;
    try {
      await CoachApi.instance.clearHistory();
      if (!mounted) return;
      setState(() => _messages = []);
    } catch (_) {
      if (!mounted) return;
      _showError('대화 초기화에 실패했어요');
    }
  }

  void _showError(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _CoachHeader(
            messageCount: _messages.length,
            onClear: _messages.isEmpty ? null : _confirmClear,
          ),
          Expanded(
            child: _loadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _historyError != null
                    ? _ErrorState(
                        message: _historyError!,
                        onRetry: _loadHistory,
                      )
                    : _buildMessages(),
          ),
          _InputBar(
            controller: _controller,
            focusNode: _focusNode,
            hasText: _hasText,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    final isEmpty = _messages.isEmpty;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const _DateDivider(date: '오늘'),
        const SizedBox(height: 18),

        if (isEmpty) ...[
          _GreetingBubble().animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 18),
          _SuggestionChips(onTap: (text) => _send(_stripPrefix(text))),
        ] else ...[
          for (int i = 0; i < _messages.length; i++) ...[
            _ChatBubble(message: _messages[i])
                .animate()
                .fadeIn(duration: 300.ms)
                .slideX(
                  begin: _messages[i].isUser ? 0.04 : -0.04,
                  end: 0,
                ),
            const SizedBox(height: 12),
          ],
        ],

        if (_sending)
          _TypingBubble().animate().fadeIn(duration: 300.ms),
      ],
    );
  }

  String _stripPrefix(String suggestion) {
    // 이모지 + 공백 제거 (UI에 보이는 prefix 제외)
    final idx = suggestion.indexOf('  ');
    return idx >= 0 ? suggestion.substring(idx + 2) : suggestion;
  }
}

// ── 헤더 ──────────────────────────────────────────────────────────────────────

class _CoachHeader extends StatelessWidget {
  final int messageCount;
  final VoidCallback? onClear;

  const _CoachHeader({required this.messageCount, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        12,
        14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF283F3B), Color(0xFF4A7A52)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A7A52).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Color(0xFF8BBF84),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 코치',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '온라인 · 당신의 하루를 함께 읽어드려요',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: '대화 초기화',
              onPressed: onClear,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.textHint,
                size: 22,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── 날짜 구분선 ───────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final String date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.surfaceVariant,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              date,
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.surfaceVariant,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

// ── 첫 인사 (히스토리 비어있을 때) ────────────────────────────────────────────

class _GreetingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _CoachAvatar(),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '안녕하세요! 오늘 하루는 어떠셨나요? 😊\n\n무엇이든 편하게 이야기해 주세요. '
              '최근 일기를 바탕으로 함께 생각해 볼게요.',
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                height: 1.65,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 추천 질문 칩 (탭하면 자동 전송) ───────────────────────────────────────────

class _SuggestionChips extends StatelessWidget {
  final void Function(String text) onTap;
  const _SuggestionChips({required this.onTap});

  static const _suggestions = [
    '🌙  수면 개선 팁이 궁금해요',
    '🌿  스트레스 해소법 알려줘',
    '📊  이번 주 감정 분석해줘',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _suggestions.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => onTap(e.value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  e.value,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
              .animate(delay: Duration(milliseconds: 100 + 80 * e.key))
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.03, end: 0);
        }).toList(),
      ),
    );
  }
}

// ── 채팅 말풍선 ───────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final CoachMessage message;
  const _ChatBubble({required this.message});

  String _formatTime(DateTime t) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final period = t.hour < 12 ? '오전' : '오후';
    final mm = t.minute.toString().padLeft(2, '0');
    return '$period $h12:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final time = _formatTime(message.createdAt.toLocal());

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          const _CoachAvatar(),
          const SizedBox(width: 10),
        ],
        if (isUser)
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: Text(
              time,
              style: GoogleFonts.notoSansKr(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          ),
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 5),
                bottomRight: Radius.circular(isUser ? 5 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: isUser
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SelectableText(
              message.content,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                height: 1.65,
                color: isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
        if (!isUser)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              time,
              style: GoogleFonts.notoSansKr(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          ),
      ],
    );
  }
}

// ── 코치 아바타 ───────────────────────────────────────────────────────────────

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF283F3B), Color(0xFF4A7A52)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.eco_rounded,
        color: Color(0xFF8BBF84),
        size: 17,
      ),
    );
  }
}

// ── 타이핑 인디케이터 ─────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _CoachAvatar(),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  // 0~1 사이 위상 시프트
                  final t = ((_ctrl.value + i * 0.18) % 1.0);
                  final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                  return Padding(
                    padding: EdgeInsets.only(right: i == 2 ? 0 : 4),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── 입력 바 ───────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final canSend = hasText && !sending;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46, maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: '코치에게 이야기해보세요...',
                  hintStyle: GoogleFonts.notoSansKr(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canSend ? onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: canSend ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(23),
                boxShadow: canSend
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: sending
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textHint,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color: canSend ? Colors.white : AppColors.textHint,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 에러 상태 ─────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😔', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
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
}
