class UserProfile {
  final String id;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final String plan; // 'free' | 'pro'

  const UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    this.avatarUrl,
    this.plan = 'free',
  });

  bool get isPro => plan == 'pro';

  /// 닉네임 첫 글자 (아바타 없을 때 placeholder)
  String get initial => nickname.isNotEmpty ? nickname[0] : '?';
}
