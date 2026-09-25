import 'package:supabase_flutter/supabase_flutter.dart';

/// 앱 전체에서 사용하는 Supabase 클라이언트 접근자
SupabaseClient get supabase => Supabase.instance.client;

/// 현재 로그인된 사용자 (없으면 null)
User? get currentUser => supabase.auth.currentUser;

/// 현재 세션 (없으면 null)
Session? get currentSession => supabase.auth.currentSession;
