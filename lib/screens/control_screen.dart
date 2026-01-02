// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _healthData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealth();
  }

  Future<void> _loadHealth() async {
    setState(() => _isLoading = true);
    try {
      _healthData = await _api.getHealth();
    } catch (e) {
      print('Health error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Kontrol'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHealth,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHealth,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sistem Durumu
                    _buildSectionTitle('📡 Sistem Durumu'),
                    const SizedBox(height: 8),
                    _buildSystemStatus(),

                    const SizedBox(height: 24),

                    // Hızlı Aksiyonlar
                    _buildSectionTitle('⚡ Hızlı Aksiyonlar'),
                    const SizedBox(height: 8),
                    _buildQuickActions(),

                    const SizedBox(height: 24),

                    // Asansör Kontrol
                    _buildSectionTitle('🛗 Asansör'),
                    const SizedBox(height: 8),
                    _buildElevatorSection(),

                    const SizedBox(height: 24),

                    // Manuel Kontroller
                    _buildSectionTitle('🔧 Manuel Kontroller'),
                    const SizedBox(height: 8),
                    _buildManualControls(),

                    const SizedBox(height: 24),

                    // Ayarlar
                    _buildSectionTitle('⚙️ Ayarlar'),
                    const SizedBox(height: 8),
                    _buildSettings(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSystemStatus() {
    final status = _healthData?['status'] ?? 'unknown';
    final isOk = status == 'ok';
    final agentStatus =
        _healthData?['agent_status'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isOk ? Icons.check_circle : Icons.error,
                  color: isOk ? Colors.green : Colors.red,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOk ? 'Sistem Çalışıyor' : 'Sistem Sorunu',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Versiyon: ${_healthData?['version'] ?? '-'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  'Kamera',
                  agentStatus['camera'] ?? 'unknown',
                  Icons.videocam,
                ),
                _buildStatusItem(
                  'AI Council',
                  agentStatus['council'] ?? 'unknown',
                  Icons.psychology,
                ),
                _buildStatusItem(
                  'LLM',
                  _healthData?['llm_ready'] == true ? 'ok' : 'degraded',
                  Icons.memory,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kamera IP: ${_healthData?['camera_ip'] ?? '-'}'),
                Text('MQTT: ${_healthData?['mqtt_broker'] ?? '-'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String status, IconData icon) {
    final isOk = status == 'ok';
    return Column(
      children: [
        Icon(
          icon,
          color: isOk ? Colors.green : Colors.orange,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (isOk ? Colors.green : Colors.orange).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isOk ? 'OK' : 'SORUN',
            style: TextStyle(
              fontSize: 10,
              color: isOk ? Colors.green : Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionButton(
          '📷 Fotoğraf Çek',
          Icons.camera_alt,
          Colors.blue,
          () async {
            final provider = context.read<AppProvider>();
            final result = await provider.capturePhoto();
            _showResult(result != null ? 'Fotoğraf çekildi' : 'Hata');
          },
        ),
        _actionButton(
          '🔍 Tam Tarama',
          Icons.document_scanner,
          Colors.purple,
          () async {
            final provider = context.read<AppProvider>();
            final success = await provider.scanAllRacks();
            _showResult(success ? 'Tarama başladı' : 'Hata');
          },
        ),
        _actionButton(
          '🏠 Home Git',
          Icons.home,
          Colors.orange,
          () async {
            final provider = context.read<AppProvider>();
            final success = await provider.goToRack(1);
            _showResult(success ? 'Raf 1\'e gidiliyor' : 'Hata');
          },
        ),
        _actionButton(
          '🔄 Yenile',
          Icons.refresh,
          Colors.green,
          () {
            context.read<AppProvider>().refreshSensorData();
            _loadHealth();
          },
        ),
      ],
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
      ),
    );
  }

  Widget _buildElevatorSection() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final status = provider.elevatorStatus;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raf ${status.rack}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pozisyon: ${status.position} step',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: status.moving
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            status.moving ? Icons.sync : Icons.check,
                            size: 16,
                            color: status.moving ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status.moving ? 'Hareket' : 'Hazır',
                            style: TextStyle(
                              color:
                                  status.moving ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    final rack = index + 1;
                    final isActive = status.rack == rack;
                    return ElevatedButton(
                      onPressed:
                          status.moving ? null : () => provider.goToRack(rack),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      child: Text('Raf $rack'),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => provider.moveElevator('up'),
                      icon: const Icon(Icons.arrow_upward),
                      tooltip: 'Yukarı',
                    ),
                    IconButton(
                      onPressed: () => provider.stopElevator(),
                      icon: const Icon(Icons.stop_circle, color: Colors.red),
                      tooltip: 'Durdur',
                    ),
                    IconButton(
                      onPressed: () => provider.moveElevator('down'),
                      icon: const Icon(Icons.arrow_downward),
                      tooltip: 'Aşağı',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _controlRow('💡 Grow Light', true, (v) {}),
            _controlRow('🌀 Fan', false, (v) {}),
            _controlRow('💧 Pompa', false, (v) {}),
            _controlRow('🌡️ Isıtıcı', false, (v) {}),
          ],
        ),
      ),
    );
  }

  Widget _controlRow(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Switch(
            value: value,
            onChanged: (v) {
              // TODO: API çağrısı
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Kontrol API\'si henüz hazır değil')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    final photoInterval = _healthData?['photo_interval_seconds'] ?? 7200;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Fotoğraf Aralığı'),
            subtitle: Text('${(photoInterval / 3600).toStringAsFixed(1)} saat'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showIntervalDialog(photoInterval),
          ),
          ListTile(
            leading: const Icon(Icons.wifi),
            title: const Text('API Adresi'),
            subtitle: Text(ApiService.baseUrl),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Hakkında'),
            subtitle: const Text('AgriMind v1.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(),
          ),
        ],
      ),
    );
  }

  void _showResult(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showIntervalDialog(int current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğraf Aralığı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('30 Dakika'),
              leading: Radio<int>(
                  value: 1800, groupValue: current, onChanged: (v) {}),
            ),
            ListTile(
              title: const Text('1 Saat'),
              leading: Radio<int>(
                  value: 3600, groupValue: current, onChanged: (v) {}),
            ),
            ListTile(
              title: const Text('2 Saat'),
              leading: Radio<int>(
                  value: 7200, groupValue: current, onChanged: (v) {}),
            ),
            ListTile(
              title: const Text('4 Saat'),
              leading: Radio<int>(
                  value: 14400, groupValue: current, onChanged: (v) {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showResult('API henüz hazır değil');
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'AgriMind',
      applicationVersion: '1.0.0',
      applicationIcon: const Text('🌱', style: TextStyle(fontSize: 48)),
      children: [
        const Text('Hidroponik Sera Yönetim Sistemi'),
        const SizedBox(height: 8),
        const Text('Raspberry Pi + ESP32 + AI'),
      ],
    );
  }
}
