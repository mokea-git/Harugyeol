import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이용약관')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _updatedAt(),
              const SizedBox(height: 20),
              _section(
                '1. 목적',
                '본 약관은 하루결 서비스(이하 "서비스")의 이용 조건 및 절차, '
                    '회사와 이용자의 권리 및 의무를 규정하는 것을 목적으로 합니다.',
              ),
              _section(
                '2. 서비스 이용',
                '이용자는 관련 법령과 본 약관에 따라 서비스를 이용해야 하며, '
                    '타인의 권리를 침해하거나 서비스 운영을 방해하는 행위를 해서는 안 됩니다.',
              ),
              _section(
                '3. 계정 및 인증',
                '로그인은 Supabase OAuth를 통해 처리됩니다. '
                    '이용자는 본인 계정 정보를 안전하게 관리할 책임이 있습니다.',
              ),
              _section(
                '4. 데이터 저장',
                '서비스 이용 중 생성되는 프로필/분석/코치 대화 데이터는 '
                    '하루결 서버의 SQLite 저장소에 보관됩니다.',
              ),
              _section(
                '5. 책임 제한',
                '회사는 안정적인 서비스를 제공하기 위해 노력하지만, '
                    '불가항력 또는 이용자 귀책 사유로 인한 손해에 대해 관련 법령 범위 내에서 책임을 부담합니다.',
              ),
              _section(
                '6. 약관 변경',
                '약관이 변경되는 경우 앱 내 공지 또는 서비스 화면을 통해 사전 안내합니다.',
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
