import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showEmailForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithKakao() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithKakao();
      // 외부 브라우저가 열린 후 이 줄은 즉시 실행됨
      // 실제 세션 완료는 onAuthStateChange → AuthGate에서 처리
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      // 외부 브라우저 종료 시 발생하는 예외는 무시
      // 세션이 정상 수립됐다면 AuthGate가 /home으로 이동시킴
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('이메일과 비밀번호를 입력해주세요.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await AuthService.instance.signInWithEmail(email, password);
      if (res.session != null && mounted) context.go('/home');
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // 로고
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '하루결',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 52),

              Text(
                '오늘 하루를\n기록해볼까요?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(height: 1.3),
              ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 8),
              Text(
                '시작하면 AI가 감정을 분석해드려요',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 52),

              // ── 카카오 로그인 버튼 ──────────────────────────
              _KakaoLoginButton(
                isLoading: _isLoading,
                onTap: _signInWithKakao,
              ).animate(delay: 450.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 16),

              // 이메일로 계속하기 (토글)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Column(
                  children: [
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _showEmailForm = !_showEmailForm),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '이메일로 계속하기',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Icon(
                              _showEmailForm
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 18,
                              color: AppColors.textHint,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showEmailForm) ...[
                      const SizedBox(height: 8),
                      _buildLabel('이메일'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'hello@example.com',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 16, right: 12),
                            child: Icon(Icons.mail_outline_rounded,
                                size: 20, color: AppColors.textHint),
                          ),
                          prefixIconConstraints:
                              BoxConstraints(minWidth: 0, minHeight: 0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('비밀번호'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '비밀번호를 입력하세요',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 16, right: 12),
                            child: Icon(Icons.lock_outline_rounded,
                                size: 20, color: AppColors.textHint),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 0, minHeight: 0),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                          suffixIconConstraints:
                              const BoxConstraints(minWidth: 0, minHeight: 0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signInWithEmail,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('로그인'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push('/register'),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary),
                          child: Text(
                            '계정이 없으신가요? 회원가입',
                            style: GoogleFonts.notoSansKr(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate(delay: 550.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 40),

              // 이용약관 안내
              Center(
                child: Text(
                  '로그인하면 이용약관 및 개인정보처리방침에 동의하게 됩니다',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: AppColors.textHint,
                    height: 1.5,
                  ),
                ),
              ).animate(delay: 700.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.notoSansKr(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );
  }
}

// ─── 카카오 로그인 버튼 ──────────────────────────────────────────────────────

class _KakaoLoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _KakaoLoginButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFEE500), // 카카오 공식 Yellow
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFEE500).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 카카오 로고 (말풍선 아이콘으로 대체)
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF191919),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Color(0xFFFEE500),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF191919),
                    strokeWidth: 2,
                  ),
                )
              else
                Text(
                  '카카오로 시작하기',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF191919),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
