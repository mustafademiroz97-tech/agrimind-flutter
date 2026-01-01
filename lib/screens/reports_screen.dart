import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/report.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  
  ReportStats? _stats;
  List<HourlyReport> _hourlyReports = [];
  List<DailyReport> _dailyReports = [];
  List<dynamic> _weeklyReports = [];
  List<dynamic> _monthlyReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _api.getReportStats(),
        _api.getHourlyReports(),
        _api.getDailyReports(),
        _api.getWeeklyReports(),
        _api.getMonthlyReports(),
      ]);
      
      setState(() {
        _stats = results[0] as ReportStats;
        _hourlyReports = results[1] as List<HourlyReport>;
        _dailyReports = results[2] as List<DailyReport>;
        _weeklyReports = results[3] as List<dynamic>;
        _monthlyReports = results[4] as List<dynamic>;
      });
    } catch (e) {
      print('Reports load error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Raporlar'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Saatlik (${_stats?.hourlyCount ?? 0})'),
            Tab(text: 'Günlük (${_stats?.dailyCount ?? 0})'),
            Tab(text: 'Haftalık (${_stats?.weeklyCount ?? 0})'),
            Tab(text: 'Aylık (${_stats?.monthlyCount ?? 0})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHourlyTab(),
                _buildDailyTab(),
                _buildGenericTab(_weeklyReports, 'Haftalık'),
                _buildGenericTab(_monthlyReports, 'Aylık'),
              ],
            ),
    );
  }

  Widget _buildHourlyTab() {
    if (_hourlyReports.isEmpty) {
      return _buildEmptyState('Saatlik rapor bulunamadı');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _hourlyReports.length,
        itemBuilder: (context, index) {
          final report = _hourlyReports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🕐 ${_formatTime(report.hourStart)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      _healthBadge(report.avgHealth),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('📷 Analiz', '${report.analysisCount}'),
                      _statItem('⚡ Aksiyon', '${report.actionCount}'),
                      _statItem('⚠️ Alert', '${report.alertCount}'),
                    ],
                  ),
                  if (report.rackHealths.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: report.rackHealths.entries.map((e) {
                        return Chip(
                          label: Text('${e.key}: ${e.value}'),
                          backgroundColor: _healthColor(e.value.toDouble()).withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyTab() {
    if (_dailyReports.isEmpty) {
      return _buildEmptyState('Günlük rapor bulunamadı');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dailyReports.length,
        itemBuilder: (context, index) {
          final report = _dailyReports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📅 ${_formatDate(report.date)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      _healthBadge(report.avgHealth),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('📷 Analiz', '${report.totalAnalyses}'),
                      _statItem('⚡ Aksiyon', '${report.totalActions}'),
                      _statItem('⚠️ Alert', '${report.totalAlerts}'),
                    ],
                  ),
                  if (report.topIssues.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Öne Çıkan Sorunlar:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...report.topIssues.map((issue) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right, size: 16),
                          Expanded(child: Text(issue)),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenericTab(List<dynamic> reports, String type) {
    if (reports.isEmpty) {
      return _buildEmptyState('$type rapor bulunamadı');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.2),
                child: Text('${index + 1}'),
              ),
              title: Text(report['period'] ?? report['week'] ?? report['month'] ?? '$type ${index + 1}'),
              subtitle: Text(
                'Analiz: ${report['stats']?['total_analyses'] ?? 0} • '
                'Aksiyon: ${report['stats']?['total_actions'] ?? 0}',
              ),
              trailing: _healthBadge(
                (report['stats']?['avg_health'] ?? 0).toDouble(),
              ),
              onTap: () => _showReportDetail(report),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Yenile'),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _healthBadge(double health) {
    final color = _healthColor(health);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${health.toStringAsFixed(0)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _healthColor(double health) {
    if (health >= 80) return Colors.green;
    if (health >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour.toString().padLeft(2, '0')}:00';
    } catch (e) {
      return isoTime;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (e) {
      return isoDate;
    }
  }

  void _showReportDetail(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rapor Detayı',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      const JsonEncoder.withIndent('  ').convert(report),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JsonEncoder {
  final String indent;
  const JsonEncoder.withIndent(this.indent);
  
  String convert(dynamic obj) {
    return _encode(obj, 0);
  }
  
  String _encode(dynamic obj, int level) {
    final prefix = indent * level;
    if (obj == null) return 'null';
    if (obj is String) return '"$obj"';
    if (obj is num || obj is bool) return obj.toString();
    if (obj is List) {
      if (obj.isEmpty) return '[]';
      final items = obj.map((e) => '$prefix$indent${_encode(e, level + 1)}').join(',\n');
      return '[\n$items\n$prefix]';
    }
    if (obj is Map) {
      if (obj.isEmpty) return '{}';
      final items = obj.entries.map((e) => '$prefix$indent"${e.key}": ${_encode(e.value, level + 1)}').join(',\n');
      return '{\n$items\n$prefix}';
    }
    return obj.toString();
  }
}
