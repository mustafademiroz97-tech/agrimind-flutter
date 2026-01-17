import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/mqtt_service.dart';
import '../widgets/sensor_gauge.dart';
import '../widgets/rack_card.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌱 AgriMind'),
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bağlantı modu göstergesi
                Tooltip(
                  message: provider.isRemoteMode ? 'İnternet' : 'Yerel',
                  child: Icon(
                    provider.isRemoteMode ? Icons.public : Icons.home,
                    color: provider.isConnected ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          if (!kIsWeb)
            Consumer<MqttService>(
              builder: (context, mqtt, _) => IconButton(
                icon: Icon(
                  mqtt.isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: mqtt.isConnected ? Colors.green : Colors.red,
                ),
                onPressed: () => mqtt.connect(),
                tooltip: mqtt.isConnected ? 'MQTT Bağlı' : 'MQTT Bağlantı Yok',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AppProvider>().refreshSensorData(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            tooltip: 'Ayarlar',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final data = provider.sensorData;

          return RefreshIndicator(
            onRefresh: provider.refreshSensorData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bağlantı durumu
                  if (!provider.isConnected)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(provider.error ?? 'Bağlantı sorunu'),
                        ],
                      ),
                    ),

                  // Kabin Ortamı
                  _buildSectionTitle('🏠 Kabin Ortamı'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SensorGauge(
                          title: 'Sıcaklık',
                          value: data.cabin.temperature,
                          unit: '°C',
                          min: 15,
                          max: 35,
                          optimal: const [20, 28],
                          icon: Icons.thermostat,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SensorGauge(
                          title: 'Nem',
                          value: data.cabin.humidity,
                          unit: '%',
                          min: 30,
                          max: 90,
                          optimal: const [60, 75],
                          icon: Icons.water_drop,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SensorGauge(
                          title: 'CO₂',
                          value: data.cabin.co2.toDouble(),
                          unit: 'ppm',
                          min: 400,
                          max: 1500,
                          optimal: const [600, 1000],
                          icon: Icons.air,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Su Tankı
                  _buildSectionTitle('💧 Su Tankı'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SensorGauge(
                          title: 'pH',
                          value: data.water.ph,
                          unit: '',
                          min: 4,
                          max: 8,
                          optimal: const [5.8, 6.5],
                          icon: Icons.science,
                          color: Colors.purple,
                          decimals: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SensorGauge(
                          title: 'EC',
                          value: data.water.ec,
                          unit: 'mS/cm',
                          min: 0,
                          max: 4,
                          optimal: const [1.5, 2.5],
                          icon: Icons.electric_bolt,
                          color: Colors.yellow,
                          decimals: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SensorGauge(
                          title: 'Su Sıcaklığı',
                          value: data.water.temperature,
                          unit: '°C',
                          min: 15,
                          max: 30,
                          optimal: const [18, 24],
                          icon: Icons.waves,
                          color: Colors.cyan,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Su seviyesi bar
                  _buildWaterLevelBar(data.water.level),

                  const SizedBox(height: 24),

                  // Raflar
                  _buildSectionTitle('🌿 Raf Durumları'),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: data.racks.isEmpty ? 4 : data.racks.length,
                    itemBuilder: (context, index) {
                      // Raf verisi yoksa boş raf göster
                      if (data.racks.isEmpty) {
                        return RackCard(rack: RackData.empty(index + 1));
                      }
                      return RackCard(rack: data.racks[index]);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Son güncelleme
                  Center(
                    child: Text(
                      'Son güncelleme: ${data.time.isNotEmpty ? data.time : "-"}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

  Widget _buildWaterLevelBar(int level) {
    Color levelColor;
    if (level < 20) {
      levelColor = Colors.red;
    } else if (level < 40) {
      levelColor = Colors.orange;
    } else {
      levelColor = Colors.blue;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.water, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Su Seviyesi'),
                  ],
                ),
                Text(
                  '$level%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: level / 100,
                minHeight: 12,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation(levelColor),
              ),
            ),
            if (level < 20)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[400], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Su seviyesi kritik!',
                      style: TextStyle(color: Colors.red[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
