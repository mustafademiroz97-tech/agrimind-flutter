// Chat mesaj modeli
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final MemoryStats? memoryStats;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? time,
    this.memoryStats,
  }) : time = time ?? DateTime.now();
}

class MemoryStats {
  final int totalAnalyses;
  final int recentCount;
  final int summaryCount;
  final int alertCount;
  final int chatCount;
  final int actionCount;
  final Map<String, int> actionTypes;
  final double avgHealthLast10;
  final String lastUpdated;

  MemoryStats({
    required this.totalAnalyses,
    required this.recentCount,
    required this.summaryCount,
    required this.alertCount,
    required this.chatCount,
    required this.actionCount,
    required this.actionTypes,
    required this.avgHealthLast10,
    required this.lastUpdated,
  });

  factory MemoryStats.fromJson(Map<String, dynamic> json) {
    return MemoryStats(
      totalAnalyses: json['total_analyses'] ?? 0,
      recentCount: json['recent_count'] ?? 0,
      summaryCount: json['summary_count'] ?? 0,
      alertCount: json['alert_count'] ?? 0,
      chatCount: json['chat_count'] ?? 0,
      actionCount: json['action_count'] ?? 0,
      actionTypes: Map<String, int>.from(json['action_types'] ?? {}),
      avgHealthLast10: (json['avg_health_last_10'] ?? 0).toDouble(),
      lastUpdated: json['last_updated'] ?? '',
    );
  }
}

// Brain yanıtı
class BrainResponse {
  final String status;
  final String? answer;
  final String time;
  final MemoryStats? memoryStats;
  final String? message;

  BrainResponse({
    required this.status,
    this.answer,
    required this.time,
    this.memoryStats,
    this.message,
  });

  bool get isSuccess => status == 'success';

  factory BrainResponse.fromJson(Map<String, dynamic> json) {
    return BrainResponse(
      status: json['status'] ?? 'error',
      answer: json['answer'],
      time: json['time'] ?? '',
      memoryStats: json['memory_stats'] != null
          ? MemoryStats.fromJson(json['memory_stats'])
          : null,
      message: json['message'],
    );
  }
}
