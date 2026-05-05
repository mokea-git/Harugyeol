import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/user_profile.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_service.dart';
import '../auth/profile_service.dart';
import '../subscription/subscription_api.dart';
import 'settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0+1',
  );

  UserProfile? _profile;
  SubscriptionStatus? _subStatus;
  bool _loading = true;
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSettings();
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        ProfileService.instance.getProfile(),
        SubscriptionApi.instance.getStatus(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as UserProfile;
          _subStatus = results[1] as SubscriptionStatus;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.instance.load();
    if (!mounted) return;
    setState(() {
      _reminderEnabled = settings.enabled;
      _reminderTime = settings.reminderTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          // ── 그라디언트 헤더 ──────────────────────────────────────
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
                child: Text(
                  '설정',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // ── 프로필 카드 ────────────────────────────────────────────
              _loading
                  ? _ProfileCardSkeleton()
                  : _ProfileCard(profile: _profile)
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.05, end: 0),

              const SizedBox(height: 16),

              // ── 구독 배너 ─────────────────────────────────────────────
              _SubscriptionBanner(status: _subStatus)
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 32),

              // ── 일반 설정 ─────────────────────────────────────────────
              _SectionTitle(title: '일반'),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: '알림 설정',
                trailing: _ToggleSwitch(
                  value: _reminderEnabled,
                  onChanged: (value) async {
                    setState(() => _reminderEnabled = value);
                    await SettingsService.instance.setReminderEnabled(value);
                    if (!mounted) return;
                    _showSnack(value ? '알림을 켰어요' : '알림을 껐어요');
                  },
                ),
              ),
              _SettingsTile(
                icon: Icons.schedule_rounded,
                label: '일기 알림 시간',
                onTap: _pickReminderTime,
                trailing: Text(
                  _formatTimeOfDay(_reminderTime),
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _SectionTitle(title: '계정'),
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: '닉네임 변경',
                onTap: () => _showNicknameDialog(context),
              ),
              _SettingsTile(
                icon: Icons.image_outlined,
                label: '프로필 사진 변경',
                onTap: _pickProfileImage,
              ),
              _SettingsTile(
                icon: Icons.download_rounded,
                label: '데이터 내보내기',
                trailing: _subStatus?.isPro != true
                    ? const _ProBadge()
                    : null,
                onTap: _subStatus?.isPro == true
                    ? _exportData
                    : () => context.push('/pro'),
              ),
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: '도움말 & FAQ',
                onTap: () => context.push('/help-faq'),
              ),

              const SizedBox(height: 24),
              _SectionTitle(title: '기타'),
              _SettingsTile(
                icon: Icons.description_outlined,
                label: '이용약관',
                onTap: () => context.push('/terms'),
              ),
              _SettingsTile(
                icon: Icons.shield_outlined,
                label: '개인정보처리방침',
                onTap: () => context.push('/privacy-policy'),
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: '앱 버전',
                onTap: _showVersionDialog,
                trailing: Text(
                  'v$_appVersion',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Center(
                child: TextButton(
                  onPressed: () => _showLogoutDialog(context),
                  child: Text(
                    '로그아웃',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 15,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],          // inner Column children
          ),            // inner Column
        ),              // SingleChildScrollView
        ),              // Expanded
        ],              // outer Column children
      ),                // outer Column
    );
  }

  void _showNicknameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: _profile?.nickname ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '닉네임 변경',
          style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '새 닉네임 입력'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '취소',
              style: GoogleFonts.notoSansKr(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await ProfileService.instance.updateNickname(name);
              _loadProfile();
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
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
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '로그아웃 하시겠어요?',
                style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '다시 로그인하면 모든 데이터를\n그대로 이용할 수 있어요',
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
                      onPressed: () async {
                        Navigator.pop(ctx);
                        ProfileService.instance.clearCache();
                        await AuthService.instance.signOut();
                        if (context.mounted) context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: const Text('로그아웃'),
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

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: '일기 알림 시간 선택',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() => _reminderTime = picked);
    await SettingsService.instance.setReminderTime(picked);
    if (!mounted) return;
    _showSnack('알림 시간이 ${_formatTimeOfDay(picked)}로 변경됐어요');
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? '오전' : '오후';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period $hour12:$minute';
  }

  Future<void> _exportData() async {
    try {
      final profile = await ProfileService.instance.getProfile(
        forceRefresh: true,
      );
      final weeklyRes = await ApiClient.instance.dio.get('/analyses/weekly');
      final coachRes = await ApiClient.instance.dio.get('/coach/history');

      final payload = {
        'exported_at': DateTime.now().toIso8601String(),
        'profile': {
          'id': profile.id,
          'email': profile.email,
          'nickname': profile.nickname,
          'avatar_url': profile.avatarUrl,
          'plan': profile.plan,
        },
        'settings': {
          'reminder_enabled': _reminderEnabled,
          'reminder_time': _formatTimeOfDay(_reminderTime),
        },
        'weekly_analyses': weeklyRes.data,
        'coach_history': coachRes.data,
      };

      final json = const JsonEncoder.withIndent('  ').convert(payload);
      await Clipboard.setData(ClipboardData(text: json));

      if (!mounted) return;
      _showSnack('데이터 JSON이 클립보드에 복사됐어요');
    } catch (_) {
      if (!mounted) return;
      _showSnack('데이터 내보내기에 실패했어요');
    }
  }

  void _showVersionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '앱 버전',
          style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '하루결 v$_appVersion',
          style: GoogleFonts.notoSansKr(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickProfileImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 2 * 1024 * 1024) {
        _showSnack('이미지가 너무 커요. 2MB 이하로 선택해 주세요');
        return;
      }

      final mimeType = _guessMimeType(file.name);
      final dataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';

      await ProfileService.instance.updateAvatarImage(dataUri);
      await _loadProfile();
      if (!mounted) return;
      _showSnack('프로필 사진이 변경됐어요');
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final serverMessage = _extractServerError(e.response?.data);
      if (status == 413) {
        _showSnack('이미지가 너무 커요. 더 작은 이미지를 선택해 주세요');
        return;
      }
      if (status == 401) {
        _showSnack('로그인이 만료됐어요. 다시 로그인해 주세요');
        return;
      }
      if (serverMessage != null) {
        _showSnack('이미지 변경 실패: $serverMessage');
        return;
      }
      _showSnack('서버 오류로 이미지 변경에 실패했어요');
    } catch (_) {
      if (!mounted) return;
      _showSnack('이미지 변경에 실패했어요');
    }
  }

  String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String? _extractServerError(dynamic data) {
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    return null;
  }
}

// ─── 프로필 카드 ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserProfile? profile;
  const _ProfileCard({this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.nickname ?? '하루결 사용자';
    final email = profile?.email ?? '';
    final initial = profile?.initial ?? '하';
    final isPro = profile?.isPro ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF283F3B), Color(0xFF3A5A42)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // 아바타
          _Avatar(avatarUrl: profile?.avatarUrl, initial: initial),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // 플랜 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF8BBF84).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPro ? 'PRO' : 'FREE',
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isPro
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF8BBF84),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 아바타 ──────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String initial;
  const _Avatar({this.avatarUrl, required this.initial});

  @override
  Widget build(BuildContext context) {
    final bytes = _dataUriBytes(avatarUrl);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _InitialFallback(initial: initial),
            )
          : avatarUrl != null && avatarUrl!.isNotEmpty
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _InitialFallback(initial: initial),
            )
          : _InitialFallback(initial: initial),
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

class _InitialFallback extends StatelessWidget {
  final String initial;
  const _InitialFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.notoSansKr(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF8BBF84),
        ),
      ),
    );
  }
}

// ─── 스켈레톤 ────────────────────────────────────────────────────────────────

class _ProfileCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1000.ms, color: Colors.white.withValues(alpha: 0.3));
  }
}

// ─── 공통 위젯 ───────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.notoSansKr(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
        title: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 22,
            ),
        onTap: onTap ?? () {},
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _ToggleSwitch({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Container(
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Subscription Banner ─────────────────────────────────────────────────────

class _SubscriptionBanner extends StatelessWidget {
  final SubscriptionStatus? status;
  const _SubscriptionBanner({this.status});

  @override
  Widget build(BuildContext context) {
    final s = status;

    if (s != null && s.plan == 'pro') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A34), Color(0xFF2D5244)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFFFD700), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('하루결 PRO 이용 중',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('모든 기능을 무제한으로 이용하고 있어요',
                    style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white60)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('PRO',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFD700))),
            ),
          ],
        ),
      );
    }

    if (s != null && s.isInTrial) {
      return GestureDetector(
        onTap: () => context.push('/pro'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.primary.withValues(alpha: 0.1),
              const Color(0xFFFFD700).withValues(alpha: 0.05),
            ], begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.access_time_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PRO 체험 중',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.secondary)),
                Text('${s.trialDaysLeft}일 후 자동으로 무료 전환돼요',
                    style: GoogleFonts.notoSansKr(
                        fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            Text('D-${s.trialDaysLeft}',
                style: GoogleFonts.notoSansKr(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
          ]),
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/pro'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.primarySurface.withValues(alpha: 0.5),
            ]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PRO로 업그레이드',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondary)),
              Text('무제한 AI 분석 · 주간 리포트 · 코치 대화',
                  style: GoogleFonts.notoSansKr(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ]),
      ),
    );
  }
}

// ─── Pro Badge ────────────────────────────────────────────────────────────────

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA726)]),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('PRO',
          style: GoogleFonts.notoSansKr(
              fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}
