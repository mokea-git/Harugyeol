import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// 앱 시작 시 인증 상태를 확인하고 적절한 화면으로 라우팅
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();

    // 인증 상태 변화 리스닝 (카카오 OAuth 콜백 처리)
    AuthService.instance.authStateChanges.listen((data) {
      if (!mounted) return;
      _routeByAuthState(data.event);
    });
  }

  void _checkAuth() {
    if (AuthService.instance.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
    }
  }

  void _routeByAuthState(AuthChangeEvent event) {
    switch (event) {
      case AuthChangeEvent.signedIn:
        context.go('/home');
      case AuthChangeEvent.signedOut:
        context.go('/login');
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 인증 확인 중 스플래시 표시
    return const Scaffold(
      backgroundColor: Color(0xFF283F3B),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8BBF84),
          strokeWidth: 2,
        ),
      ),
    );
  }
}
