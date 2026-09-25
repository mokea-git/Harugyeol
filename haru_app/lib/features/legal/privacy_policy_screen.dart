import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보처리방침')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _updatedAt(),
              const SizedBox(height: 20),
              _section(
                '1. 수집 항목',
                '서비스는 로그인 식별값(UID), 이메일, 닉네임, 프로필 이미지 URL, '
                    '일기 분석 결과 및 코치 대화 내역을 처리할 수 있습니다.',
              ),
              _section(
                '2. 수집 및 이용 목적',
                '회원 식별, 서비스 제공, AI 분석/코치 기능 제공, '
                    '고객 문의 대응 및 서비스 품질 개선 목적에 활용됩니다.',
              ),
              _section(
                '3. 보관 및 처리 방식',
                '인증은 Supabase OAuth를 사용하며, 서비스 데이터는 하루결 백엔드의 '
                    'SQLite 저장소에서 관리됩니다.',
              ),
              _section(
                '4. 보유 기간',
                '법령에 별도 규정이 없는 한, 이용자가 계정 삭제를 요청하거나 '
                    '서비스 목적 달성 시 지체 없이 파기합니다.',
              ),
              _section(
                '5. 이용자 권리',
                '이용자는 본인 정보의 조회, 정정, 삭제를 요청할 수 있으며, '
                    '관련 요청은 고객지원 채널을 통해 접수할 수 있습니다.',
              ),
              _section(
                '6. 문의',
                '개인정보 처리 관련 문의는 운영자에게 전달해 주세요. '
                    '정책 변경 시 앱 공지로 안내합니다.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _updatedAt() {
    return Text(
      '최종 업데이트: 2026-05-04',
      style: GoogleFonts.notoSansKr(fontSize: 12, color: AppColors.textHint),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSansKr(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              height: 1.65,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
