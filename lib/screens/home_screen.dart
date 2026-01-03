import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/mqtt_service.dart';
import 'dashboard_screen.dart';
import 'brain_chat_screen.dart';
import 'camera_screen.dart';
import 'reports_screen.dart';
import 'control_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    BrainChatScreen(),
    CameraScreen(),
    ReportsScreen(),
    ControlScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConnections();
    });
  }

  Future<void> _initializeConnections() async {
    final provider = context.read<AppProvider>();
    final mqtt = context.read<MqttService>();
    
    // Her zaman HTTP polling başlat (fallback)
    provider.startPolling();
    
    // MQTT bağlantısını dene (yerel ağ için)
    try {
      await mqtt.connect().timeout(const Duration(seconds: 3));
      if (mqtt.isConnected) {
        debugPrint('✅ MQTT bağlı - yerel ağ modu');
        _setupMqttListeners(mqtt);
      }
    } catch (e) {
      debugPrint('ℹ️ MQTT bağlanamadı - HTTP API modu: $e');
    }
  }

  void _setupMqttListeners(MqttService mqtt) {
    final provider = context.read<AppProvider>();

    mqtt.sensorStream.listen((data) {
      provider.updateSensorData(data);
    });

    mqtt.elevatorStream.listen((status) {
      provider.updateElevatorStatus(status);
    });

    mqtt.alertStream.listen((alert) {
      provider.addAlert(alert);
      _showAlertSnackbar(alert);
    });
  }

  void _showAlertSnackbar(alert) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(alert.severityIcon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(alert.message)),
          ],
        ),
        backgroundColor: alert.severityColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Beyin',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Kamera',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Raporlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Kontrol',
          ),
        ],
      ),
    );
  }
}
