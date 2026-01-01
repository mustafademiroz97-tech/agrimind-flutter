// Rapor modelleri
class ReportStats {
  final int hourlyCount;
  final int dailyCount;
  final int weeklyCount;
  final int monthlyCount;

  ReportStats({
    required this.hourlyCount,
    required this.dailyCount,
    required this.weeklyCount,
    required this.monthlyCount,
  });

  factory ReportStats.fromJson(Map<String, dynamic> json) {
    return ReportStats(
      hourlyCount: json['hourly_count'] ?? 0,
      dailyCount: json['daily_count'] ?? 0,
      weeklyCount: json['weekly_count'] ?? 0,
      monthlyCount: json['monthly_count'] ?? 0,
    );
  }
}

class HourlyReport {
  final String hourStart;
  final String hourEnd;
  final int analysisCount;
  final int actionCount;
  final int alertCount;
  final double avgHealth;
  final Map<String, int> rackHealths;

  HourlyReport({
    required this.hourStart,
    required this.hourEnd,
    required this.analysisCount,
    required this.actionCount,
    required this.alertCount,
    required this.avgHealth,
    required this.rackHealths,
  });

  factory HourlyReport.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? {};
    return HourlyReport(
      hourStart: json['hour_start'] ?? '',
      hourEnd: json['hour_end'] ?? '',
      analysisCount: stats['analysis_count'] ?? 0,
      actionCount: stats['action_count'] ?? 0,
      alertCount: stats['alert_count'] ?? 0,
      avgHealth: (stats['avg_health'] ?? 0).toDouble(),
      rackHealths: Map<String, int>.from(stats['rack_healths'] ?? {}),
    );
  }
}

class DailyReport {
  final String date;
  final int totalAnalyses;
  final int totalActions;
  final int totalAlerts;
  final double avgHealth;
  final List<String> topIssues;

  DailyReport({
    required this.date,
    required this.totalAnalyses,
    required this.totalActions,
    required this.totalAlerts,
    required this.avgHealth,
    required this.topIssues,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? {};
    return DailyReport(
      date: json['date'] ?? '',
      totalAnalyses: stats['total_analyses'] ?? 0,
      totalActions: stats['total_actions'] ?? 0,
      totalAlerts: stats['total_alerts'] ?? 0,
      avgHealth: (stats['avg_health'] ?? 0).toDouble(),
      topIssues: List<String>.from(stats['top_issues'] ?? []),
    );
  }
}
