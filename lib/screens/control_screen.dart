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

  // Ayarlar - varsayılan değerler
  double _phMin = 5.5;
  double _phMax = 6.5;
  double _ecMin = 1.0;
  double _ecMax = 2.0;
  TimeOfDay _dayStart = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _dayEnd = const TimeOfDay(hour: 22, minute: 0);
  double _dayTemp = 24.0;
  double _nightTemp = 18.0;
  double _tempHysteresis = 1.0; // Sıcaklık açma/kapama farkı
  int _photoIntervalHours = 2; // Fotoğraf aralığı (saat)

  @override
  void initState() {
    super.initState();
    _loadHealth();
    _loadSettings();
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

  Future<void> _loadSettings() async {
    try {
      final settings = await _api.getSettings();
      if (settings != null && mounted) {
        setState(() {
          _phMin = (settings['ph_min'] ?? 5.5).toDouble();
          _phMax = (settings['ph_max'] ?? 6.5).toDouble();
          _ecMin = (settings['ec_min'] ?? 1.0).toDouble();
          _ecMax = (settings['ec_max'] ?? 2.0).toDouble();
          _dayTemp = (settings['day_temp'] ?? 24.0).toDouble();
          _nightTemp = (settings['night_temp'] ?? 18.0).toDouble();
          _tempHysteresis = (settings['temp_hysteresis'] ?? 1.0).toDouble();
          _photoIntervalHours = (settings['photo_interval_hours'] ?? 2).toInt();

          final dayStartHour = settings['day_start_hour'] ?? 6;
          final dayEndHour = settings['day_end_hour'] ?? 22;
          _dayStart = TimeOfDay(hour: dayStartHour, minute: 0);
          _dayEnd = TimeOfDay(hour: dayEndHour, minute: 0);
        });
      }
    } catch (e) {
      print('Settings load error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _api.updateSettings({
        'ph_min': _phMin,
        'ph_max': _phMax,
        'ec_min': _ecMin,
        'ec_max': _ecMax,
        'day_temp': _dayTemp,
        'night_temp': _nightTemp,
        'temp_hysteresis': _tempHysteresis,
        'photo_interval_hours': _photoIntervalHours,
        'day_start_hour': _dayStart.hour,
        'day_end_hour': _dayEnd.hour,
      });
      _showResult('✅ Ayarlar kaydedildi');
    } catch (e) {
      _showResult('❌ Kaydetme hatası');
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

                    // Manuel Kontroller (cihazlar)
                    _buildSectionTitle('🔧 Manuel Kontroller'),
                    const SizedBox(height: 8),
                    _buildManualControls(),

                    const SizedBox(height: 24),

                    // Manuel Dozlama
                    _buildSectionTitle('💊 Manuel Dozlama'),
                    const SizedBox(height: 8),
                    _buildDosingControls(),

                    const SizedBox(height: 24),

                    // pH ve EC Eşikleri
                    _buildSectionTitle('🎯 pH / EC Eşikleri'),
                    const SizedBox(height: 8),
                    _buildThresholdSettings(),

                    const SizedBox(height: 24),

                    // Gündüz/Gece Ayarları
                    _buildSectionTitle('🌅 Gündüz / Gece Ayarları'),
                    const SizedBox(height: 8),
                    _buildDayNightSettings(),

                    const SizedBox(height: 24),

                    // Sıcaklık Hedefleri
                    _buildSectionTitle('🌡️ Sıcaklık Hedefleri'),
                    const SizedBox(height: 8),
                    _buildTemperatureSettings(),

                    const SizedBox(height: 24),

                    // Tarama Ayarları
                    _buildSectionTitle('📷 Tarama Ayarları'),
                    const SizedBox(height: 8),
                    _buildScanSettings(),

                    const SizedBox(height: 24),

                    // Kaydet butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Ayarları Kaydet'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                  'MQTT',
                  _healthData?['mqtt_connected'] == true ? 'ok' : 'degraded',
                  Icons.wifi,
                ),
                _buildStatusItem(
                  'LLM',
                  _healthData?['llm_ready'] == true ? 'ok' : 'degraded',
                  Icons.memory,
                ),
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

  Widget _buildManualControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _controlRow('💡 Grow Light', 'light', Icons.lightbulb),
            _controlRow('🌀 Fan', 'fan', Icons.air),
            _controlRow('💧 Pompa', 'pump', Icons.water_drop),
            _controlRow('🌡️ Isıtıcı', 'heater', Icons.whatshot),
            _controlRow('❄️ Klima', 'cooler', Icons.ac_unit),
          ],
        ),
      ),
    );
  }

  Widget _controlRow(String label, String device, IconData icon) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final isOn = provider.deviceStates[device] ?? false;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: isOn ? Colors.green : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 16)),
              ),
              Switch(
                value: isOn,
                onChanged: (v) async {
                  final success = await provider.toggleDevice(device, v);
                  if (!success) {
                    _showResult('❌ Cihaz kontrol hatası');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDosingControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _dosingButton('🅰️ A Besini', 'nutrient_a', Colors.blue),
            const SizedBox(height: 12),
            _dosingButton('🅱️ B Besini', 'nutrient_b', Colors.green),
            const SizedBox(height: 12),
            _dosingButton('⬇️ pH Düşürücü', 'ph_down', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _dosingButton(String label, String pumpId, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
        Row(
          children: [
            _doseAmountButton(pumpId, 1, color),
            const SizedBox(width: 8),
            _doseAmountButton(pumpId, 5, color),
            const SizedBox(width: 8),
            _doseAmountButton(pumpId, 10, color),
          ],
        ),
      ],
    );
  }

  Widget _doseAmountButton(String pumpId, int ml, Color color) {
    return ElevatedButton(
      onPressed: () => _doPump(pumpId, ml),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        minimumSize: const Size(50, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text('${ml}ml'),
    );
  }

  Future<void> _doPump(String pumpId, int ml) async {
    try {
      _showResult('💊 $pumpId: ${ml}ml dozlanıyor...');
      final success = await _api.doPump(pumpId, ml);
      _showResult(success ? '✅ Dozlama tamamlandı' : '❌ Dozlama hatası');
    } catch (e) {
      _showResult('❌ Hata: $e');
    }
  }

  Widget _buildThresholdSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // pH Range
            Row(
              children: [
                const Icon(Icons.science, color: Colors.purple),
                const SizedBox(width: 12),
                const Text('pH Aralığı:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text(
                  '${_phMin.toStringAsFixed(1)} - ${_phMax.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: RangeValues(_phMin, _phMax),
              min: 4.0,
              max: 8.0,
              divisions: 40,
              labels: RangeLabels(
                _phMin.toStringAsFixed(1),
                _phMax.toStringAsFixed(1),
              ),
              onChanged: (values) {
                setState(() {
                  _phMin = values.start;
                  _phMax = values.end;
                });
              },
            ),
            const Divider(),
            // EC Range
            Row(
              children: [
                const Icon(Icons.electric_bolt, color: Colors.amber),
                const SizedBox(width: 12),
                const Text('EC Aralığı:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text(
                  '${_ecMin.toStringAsFixed(1)} - ${_ecMax.toStringAsFixed(1)} mS/cm',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: RangeValues(_ecMin, _ecMax),
              min: 0.5,
              max: 3.5,
              divisions: 30,
              labels: RangeLabels(
                _ecMin.toStringAsFixed(1),
                _ecMax.toStringAsFixed(1),
              ),
              onChanged: (values) {
                setState(() {
                  _ecMin = values.start;
                  _ecMax = values.end;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayNightSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Işıklar gündüz saatinde açılır, gece saatinde kapanır.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Gündüz başlangıç
            ListTile(
              leading: const Icon(Icons.wb_sunny, color: Colors.orange),
              title: const Text('Gündüz Başlangıcı'),
              subtitle: const Text('Işıklar açılır'),
              trailing: TextButton(
                onPressed: () => _selectTime(true),
                child: Text(
                  _formatTime(_dayStart),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Gece başlangıç
            ListTile(
              leading: const Icon(Icons.nightlight_round, color: Colors.indigo),
              title: const Text('Gece Başlangıcı'),
              subtitle: const Text('Işıklar kapanır'),
              trailing: TextButton(
                onPressed: () => _selectTime(false),
                child: Text(
                  _formatTime(_dayEnd),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _dayStart : _dayEnd,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _dayStart = picked;
        } else {
          _dayEnd = picked;
        }
      });
    }
  }

  Widget _buildTemperatureSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.thermostat, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hedef ±${_tempHysteresis.toStringAsFixed(1)}°C farkla açılıp kapanır.\n'
                      'Örn: ${_dayTemp.toStringAsFixed(0)}°C hedef → '
                      '${(_dayTemp + _tempHysteresis).toStringAsFixed(0)}°C\'de klima açılır, '
                      '${_dayTemp.toStringAsFixed(0)}°C\'de kapanır.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Gündüz sıcaklık
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.orange),
                const SizedBox(width: 12),
                const Text('Gündüz Hedefi:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text(
                  '${_dayTemp.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            Slider(
              value: _dayTemp,
              min: 18,
              max: 30,
              divisions: 24,
              label: '${_dayTemp.toStringAsFixed(0)}°C',
              activeColor: Colors.orange,
              onChanged: (v) => setState(() => _dayTemp = v),
            ),
            const Divider(),
            // Gece sıcaklık
            Row(
              children: [
                const Icon(Icons.nightlight_round, color: Colors.indigo),
                const SizedBox(width: 12),
                const Text('Gece Hedefi:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text(
                  '${_nightTemp.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            Slider(
              value: _nightTemp,
              min: 12,
              max: 24,
              divisions: 24,
              label: '${_nightTemp.toStringAsFixed(0)}°C',
              activeColor: Colors.indigo,
              onChanged: (v) => setState(() => _nightTemp = v),
            ),
            const Divider(),
            // Hysteresis (açma/kapama farkı)
            Row(
              children: [
                const Icon(Icons.swap_vert, color: Colors.grey),
                const SizedBox(width: 12),
                const Text('Açma/Kapama Farkı:',
                    style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text(
                  '±${_tempHysteresis.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _tempHysteresis,
              min: 0.5,
              max: 3.0,
              divisions: 10,
              label: '±${_tempHysteresis.toStringAsFixed(1)}°C',
              onChanged: (v) => setState(() => _tempHysteresis = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt, color: Colors.purple),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Otomatik tarama belirtilen aralıkla tüm rafları tarar.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Fotoğraf aralığı
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.purple),
                const SizedBox(width: 12),
                const Text('Tarama Aralığı:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text(
                  '$_photoIntervalHours saat',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1s')),
                ButtonSegment(value: 2, label: Text('2s')),
                ButtonSegment(value: 4, label: Text('4s')),
                ButtonSegment(value: 6, label: Text('6s')),
              ],
              selected: {_photoIntervalHours},
              onSelectionChanged: (Set<int> selected) {
                setState(() => _photoIntervalHours = selected.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResult(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
