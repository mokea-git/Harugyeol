import '../../core/models/user_profile.dart';
import '../../core/network/api_client.dart';
import '../../core/supabase/supabase_client.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  UserProfile? _cached;

  /// 프로필 로드 (캐시 우선, 필요시 서버 SQLite 조회)
  Future<UserProfile> getProfile({bool forceRefresh = false}) async {
    if (_cached != null && !forceRefresh) return _cached!;

    final user = currentUser!;
    final meta = user.userMetadata ?? {};
    try {
      final res = await ApiClient.instance.dio.get('/profiles/me');
      final data = (res.data as Map).cast<String, dynamic>();

      _cached = UserProfile(
        id: (data['id'] as String?) ?? user.id,
        email: (data['email'] as String?)?.isNotEmpty == true
            ? data['email'] as String
            : (user.email ?? ''),
        nickname: (data['nickname'] as String?)?.isNotEmpty == true
            ? data['nickname'] as String
            : _metaName(meta),
        avatarUrl: (data['avatar_url'] as String?)?.isNotEmpty == true
            ? data['avatar_url'] as String
            : _metaAvatar(meta),
        plan: (data['plan'] as String?) ?? 'free',
      );
    } catch (_) {
      // 서버 실패 시 OAuth 메타데이터 fallback
      _cached = UserProfile(
        id: user.id,
        email: user.email ?? '',
        nickname: _metaName(meta),
        avatarUrl: _metaAvatar(meta),
        plan: 'free',
      );
    }

    return _cached!;
  }

  /// 닉네임 업데이트
  Future<void> updateNickname(String nickname) async {
    final current = _cached ?? await getProfile();
    final res = await ApiClient.instance.dio.patch(
      '/profiles/me',
      data: {'nickname': nickname},
    );
    final data = (res.data as Map).cast<String, dynamic>();
    _cached = UserProfile(
      id: (data['id'] as String?) ?? current.id,
      email: (data['email'] as String?) ?? current.email,
      nickname: (data['nickname'] as String?) ?? nickname,
      avatarUrl: (data['avatar_url'] as String?) ?? current.avatarUrl,
      plan: (data['plan'] as String?) ?? current.plan,
    );
  }

  /// 프로필 이미지 업데이트 (URL 또는 data URI)
  Future<void> updateAvatarImage(String avatarUrl) async {
    final current = _cached ?? await getProfile();
    final res = await ApiClient.instance.dio.patch(
      '/profiles/me',
      data: {'avatar_url': avatarUrl},
    );
    final data = (res.data as Map).cast<String, dynamic>();
    _cached = UserProfile(
      id: (data['id'] as String?) ?? current.id,
      email: (data['email'] as String?) ?? current.email,
      nickname: (data['nickname'] as String?) ?? current.nickname,
      avatarUrl: (data['avatar_url'] as String?) ?? avatarUrl,
      plan: (data['plan'] as String?) ?? current.plan,
    );
  }

  void clearCache() => _cached = null;

  // ── helpers ─────────────────────────────────────────────
  String _metaName(Map<String, dynamic> meta) {
    return (meta['full_name'] as String?) ??
        (meta['name'] as String?) ??
        (meta['preferred_username'] as String?) ??
        '하루결 사용자';
  }

  String? _metaAvatar(Map<String, dynamic> meta) {
    return (meta['avatar_url'] as String?) ?? (meta['picture'] as String?);
  }
}
