import '../../core/network/api_client.dart';
import '../auth/profile_service.dart';

class SubscriptionStatus {
  final String plan; // 'free' | 'trial' | 'pro'
  final bool isPro;
  final bool isInTrial;
  final int trialDaysLeft;

  const SubscriptionStatus({
    required this.plan,
    required this.isPro,
    required this.isInTrial,
    required this.trialDaysLeft,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      plan: (json['plan'] as String?) ?? 'free',
      isPro: (json['isPro'] as bool?) ?? false,
      isInTrial: (json['isInTrial'] as bool?) ?? false,
      trialDaysLeft: (json['trialDaysLeft'] as int?) ?? 0,
    );
  }

  factory SubscriptionStatus.free() => const SubscriptionStatus(
        plan: 'free',
        isPro: false,
        isInTrial: false,
        trialDaysLeft: 0,
      );

  String get label {
    if (plan == 'pro') return 'PRO';
    if (isInTrial) return '체험 D-$trialDaysLeft';
    return '무료';
  }
}

class SubscriptionApi {
  SubscriptionApi._();
  static final SubscriptionApi instance = SubscriptionApi._();

  /// 현재 구독 상태 조회
  Future<SubscriptionStatus> getStatus() async {
    try {
      final res = await ApiClient.instance.dio.get('/subscriptions/status');
      final data = (res.data as Map).cast<String, dynamic>();
      return SubscriptionStatus.fromJson(data);
    } catch (_) {
      return SubscriptionStatus.free();
    }
  }

  /// 7일 무료 체험 시작
  Future<SubscriptionStatus> startTrial() async {
    final res = await ApiClient.instance.dio.post('/subscriptions/trial');
    final data = (res.data as Map).cast<String, dynamic>();
    final status = SubscriptionStatus.fromJson(data);
    // 프로필 캐시 갱신
    await ProfileService.instance.getProfile(forceRefresh: true);
    return status;
  }
}
