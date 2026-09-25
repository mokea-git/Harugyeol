import '../../core/network/api_client.dart';

class CoachMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  const CoachMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => role == 'user';

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      role: (json['role'] as String?) ?? 'assistant',
      content: (json['content'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

class CoachApi {
  CoachApi._();
  static final CoachApi instance = CoachApi._();

  /// 최근 대화 히스토리 (오래된 것부터 정렬)
  Future<List<CoachMessage>> getHistory() async {
    final res = await ApiClient.instance.dio.get('/coach/history');
    final raw = res.data;
    if (raw is! List) return const <CoachMessage>[];
    return raw
        .whereType<Map>()
        .map((e) => CoachMessage.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// 메시지 전송 → AI 응답 텍스트 반환
  Future<String> sendMessage(String message) async {
    final res = await ApiClient.instance.dio.post(
      '/coach/message',
      data: {'message': message},
    );
    final data = (res.data as Map).cast<String, dynamic>();
    return (data['message'] as String?) ?? '';
  }

  /// 대화 초기화
  Future<void> clearHistory() async {
    await ApiClient.instance.dio.delete('/coach/history');
  }
}
