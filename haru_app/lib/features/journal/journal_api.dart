import '../../core/network/api_client.dart';

class JournalAnalysis {
  final String id;
  final List<String> emotions;
  final List<String> habits;
  final String feedback;
  final String? summary;
  final String createdAt;

  const JournalAnalysis({
    required this.id,
    required this.emotions,
    required this.habits,
    required this.feedback,
    required this.summary,
    required this.createdAt,
  });

  factory JournalAnalysis.fromJson(Map<String, dynamic> json) {
    final emotionsRaw = json['emotions'];
    final habitsRaw = json['habits'];

    return JournalAnalysis(
      id: (json['id'] as String?) ?? '',
      emotions: emotionsRaw is List
          ? emotionsRaw.whereType<String>().toList()
          : const <String>[],
      habits: habitsRaw is List
          ? habitsRaw.whereType<String>().toList()
          : const <String>[],
      feedback: (json['feedback'] as String?) ?? '',
      summary: json['summary'] as String?,
      createdAt: (json['created_at'] as String?) ?? '',
    );
  }
}

class JournalEntry {
  final String id;
  final String userId;
  final String content;
  final String date;
  final String createdAt;
  final JournalAnalysis? analysis;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.content,
    required this.date,
    required this.createdAt,
    required this.analysis,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final analysisRaw = json['analysis'];
    return JournalEntry(
      id: (json['id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      date: (json['date'] as String?) ?? '',
      createdAt: (json['created_at'] as String?) ?? '',
      analysis: analysisRaw is Map
          ? JournalAnalysis.fromJson(analysisRaw.cast<String, dynamic>())
          : null,
    );
  }
}

class JournalApi {
  JournalApi._();
  static final JournalApi instance = JournalApi._();

  Future<List<JournalEntry>> listJournals() async {
    final res = await ApiClient.instance.dio.get('/journals');
    final raw = res.data;
    if (raw is! List) return const <JournalEntry>[];

    return raw
        .whereType<Map>()
        .map((e) => JournalEntry.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<JournalEntry> getJournal(String id) async {
    final res = await ApiClient.instance.dio.get('/journals/$id');
    return JournalEntry.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<JournalEntry> createJournal({
    required String content,
    String? date,
    bool analyze = true,
  }) async {
    final data = {'content': content, 'date': date, 'analyze': analyze}
      ..removeWhere((_, value) => value == null);

    final res = await ApiClient.instance.dio.post('/journals', data: data);
    return JournalEntry.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<JournalEntry> updateJournal({
    required String id,
    required String content,
  }) async {
    final res = await ApiClient.instance.dio.put(
      '/journals/$id',
      data: {'content': content},
    );
    return JournalEntry.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<void> deleteJournal(String id) async {
    await ApiClient.instance.dio.delete('/journals/$id');
  }
}
