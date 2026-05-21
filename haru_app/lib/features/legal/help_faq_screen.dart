import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('도움말 & FAQ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              '자주 묻는 질문',
              style: GoogleFonts.notoSansKr(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _faq(
              question: '로그인이 안 돼요.',
              answer:
                  '네트워크 연결을 확인한 뒤 다시 시도해 주세요. 계속 실패하면 앱을 재실행하고 OAuth 로그인 버튼을 다시 눌러주세요.',
            ),
            _faq(
              question: '프로필 이름/사진은 어디에 저장되나요?',
              answer:
                  '로그인 인증은 Supabase OAuth를 사용하고, 프로필 데이터는 하루결 백엔드(SQLite)에 저장됩니다.',
            ),
            _faq(
              question: '데이터 내보내기는 어떻게 쓰나요?',
              answer:
                  '설정의 "데이터 내보내기"를 누르면 JSON이 클립보드에 복사됩니다. 메모 앱 등에 붙여넣어 보관할 수 있습니다.',
            ),
            _faq(
              question: '알림 시간은 어떻게 바꾸나요?',
              answer:
                  '설정의 "일기 알림 시간"을 눌러 원하는 시간을 선택하세요. 알림 설정이 꺼져 있으면 알림이 동작하지 않습니다.',
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '추가 문의: support@harugyeol.com',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faq({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            question,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            Text(
              answer,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
