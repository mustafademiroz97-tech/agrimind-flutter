import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  List<Map<String, dynamic>> _hourlyReports = [];
  List<Map<String, dynamic>> _dailyReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final hourly = await _api.getHourlyReports(limit: 24);
      final daily = await _api.getDailyReports(limit: 14);
      setState(() {
        _hourlyReports = List<Map<String, dynamic>>.from(hourly);
        _dailyReports = List<Map<String, dynamic>>.from(daily);
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
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: '2 Saatlik'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Günlük'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHourlyList(),
                _buildDailyList(),
              ],
            ),
    );
  }

  Widget _buildHourlyList() {
    if (_hourlyReports.isEmpty) {
      return _buildEmptyState('2 saatlik rapor henüz yok',
          'Her 2 saatte bir otomatik rapor oluşturulur');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _hourlyReports.length,
      itemBuilder: (context, index) {
        return _HourlyReportCard(report: _hourlyReports[index]);
      },
    );
  }

  Widget _buildDailyList() {
    if (_dailyReports.isEmpty) {
      return _buildEmptyState(
          'Günlük rapor henüz yok', 'Gün sonunda otomatik özet oluşturulur');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _dailyReports.length,
      itemBuilder: (context, index) {
        return _DailyReportCard(report: _dailyReports[index]);
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// 2 Saatlik Rapor Kartı
class _HourlyReportCard extends StatelessWidget {
  final Map<String, dynamic> report;

  const _HourlyReportCard({required this.report});

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      // "2026-01-03T10:00:00" formatından saat al
      if (timeStr.contains('T')) {
        final timePart = timeStr.split('T')[1];
        return timePart.substring(0, 5);
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }

  Color _getHealthColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(report['time'] ?? report['created']);
    final racks = report['racks'] as Map<String, dynamic>? ?? {};
    final sensors = report['sensors'] as Map<String, dynamic>? ?? {};
    final avgHealth = report['avg_health'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🕐 $time',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getHealthColor(avgHealth).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '❤️ $avgHealth',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getHealthColor(avgHealth)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sensör Özeti
            if (sensors.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (sensors['temp'] != null)
                    _buildSensorChip(
                        '🌡️ ${sensors['temp']}°C', Colors.deepOrange),
                  if (sensors['humidity'] != null)
                    _buildSensorChip(
                        '💧 ${sensors['humidity']}%', Colors.lightBlue),
                  if (sensors['light'] != null)
                    _buildSensorChip(
                        '☀️ ${sensors['light']} lux', Colors.amber),
                  if (sensors['ph'] != null)
                    _buildSensorChip('🧪 pH ${sensors['ph']}', Colors.purple),
                  if (sensors['ec'] != null)
                    _buildSensorChip(
                        '⚡ EC ${sensors['ec']}', Colors.tealAccent),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Raf Durumları
            if (racks.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 4),
              ...racks.entries.map((e) {
                final rackData = e.value as Map<String, dynamic>? ?? {};
                final health = rackData['health'] ?? 0;
                final disease = rackData['disease'] ?? 'yok';
                final growth = rackData['growth'] ?? '?';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('🌱 ${e.key}:',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getHealthColor(health).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('$health/100',
                            style: TextStyle(
                                fontSize: 12, color: _getHealthColor(health))),
                      ),
                      const SizedBox(width: 6),
                      Text('$growth',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[400])),
                      if (disease != 'yok' && disease != 'bitki_yok') ...[
                        const SizedBox(width: 6),
                        Text('⚠️ $disease',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.orange)),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSensorChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

// Günlük Rapor Kartı
class _DailyReportCard extends StatefulWidget {
  final Map<String, dynamic> report;

  const _DailyReportCard({required this.report});

  @override
  State<_DailyReportCard> createState() => _DailyReportCardState();
}

class _DailyReportCardState extends State<_DailyReportCard> {
  bool _isExpanded = false;

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final date = _formatDate(report['date']);
    final text = report['text'] ?? report['summary'] ?? '';
    final scanCount = report['scan_count'] ?? report['analysis_count'] ?? 0;
    final avgHealth = report['avg_health'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    avgHealth >= 70
                        ? Icons.check_circle
                        : avgHealth >= 40
                            ? Icons.info
                            : Icons.warning,
                    color: avgHealth >= 70
                        ? Colors.green
                        : avgHealth >= 40
                            ? Colors.orange
                            : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📅 $date',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$scanCount tarama • Ort. Sağlık: $avgHealth/100',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
              if (_isExpanded && text.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                SelectableText(
                  text,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
