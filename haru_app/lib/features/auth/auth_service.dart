import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../subscription/purchase_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// 카카오 OAuth 로그인
  /// Supabase가 카카오 인증 페이지를 열고 콜백을 처리합니다.
  Future<void> signInWithKakao() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: _redirectTo,
      // externalApplication: 외부 브라우저 사용 → 딥링크 복귀가 안정적
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  /// 이메일 + 비밀번호 로그인 (개발용 fallback)
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  /// 이메일 회원가입 (개발용 fallback)
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return supabase.auth.signUp(email: email, password: password);
  }

  /// 로그아웃
  Future<void> signOut() async {
    await PurchaseService.instance.logout();
    await supabase.auth.signOut();
  }

  /// 인증 상태 스트림 (로그인/로그아웃 변화 감지)
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// 현재 로그인 여부
  bool get isLoggedIn => currentUser != null;

  /// OAuth 리다이렉트 URI
  /// - iOS/Android: 앱 URL 스킴
  /// - Web: null (Supabase가 알아서 처리)
  String? get _redirectTo {
    if (kIsWeb) return null;
    return 'io.supabase.harugyeol://login-callback/';
  }
}
