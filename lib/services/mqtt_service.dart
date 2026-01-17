import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import '../models/sensor_data.dart';
import '../models/elevator_status.dart';
import '../models/alert.dart';

class MqttService extends ChangeNotifier {
  // Web için WebSocket, native için TCP
  static const String broker = '192.168.0.3';
  static const int tcpPort = 1883;
  static const int wsPort = 9001;
  static const String clientId = 'agrimind_flutter_app';

  MqttClient? _client;
  bool _isConnected = false;

  // Streams
  final _sensorController = StreamController<SensorData>.broadcast();
  final _cabinSensorController = StreamController<Map<String, dynamic>>.broadcast();
  final _elevatorController = StreamController<ElevatorStatus>.broadcast();
  final _alertController = StreamController<BrainAlert>.broadcast();
  final _brainResponseController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _fanStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _heaterStatusController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<SensorData> get sensorStream => _sensorController.stream;
  Stream<Map<String, dynamic>> get cabinSensorStream => _cabinSensorController.stream;
  Stream<ElevatorStatus> get elevatorStream => _elevatorController.stream;
  Stream<BrainAlert> get alertStream => _alertController.stream;
  Stream<Map<String, dynamic>> get brainResponseStream =>
      _brainResponseController.stream;
  Stream<Map<String, dynamic>> get fanStatusStream => _fanStatusController.stream;
  Stream<Map<String, dynamic>> get heaterStatusStream => _heaterStatusController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    // Web platformunda WebSocket, diğerlerinde TCP kullan
    if (kIsWeb) {
      final wsUrl = 'ws://$broker:$wsPort/mqtt';
      _client = MqttBrowserClient(wsUrl, clientId);
    } else {
      _client = MqttServerClient(broker, clientId);
      (_client as MqttServerClient).port = tcpPort;
      // Bağlantı timeout'u kısa tut
      (_client as MqttServerClient).connectTimeoutPeriod = 3000;
    }

    _client!.keepAlivePeriod = 60;
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.logging(on: false);
    _client!.autoReconnect = false; // Manuel kontrol edeceğiz

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(
            '${clientId}_${DateTime.now().millisecondsSinceEpoch}')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect().timeout(const Duration(seconds: 3));
    } catch (e) {
      print('MQTT: Yerel ağa bağlanılamadı (normal) - $e');
      _client?.disconnect();
      // Sessizce geç, HTTP API çalışacak
    }
  }

  void _onConnected() {
    print('✅ MQTT Connected');
    _isConnected = true;
    notifyListeners();
    _subscribeTopics();
  }

  void _onDisconnected() {
    print('❌ MQTT Disconnected');
    _isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) connect();
    });
  }

  void _subscribeTopics() {
    if (_client == null) return;

    // Sensör verileri
    _client!.subscribe('agrimind/sensors/data', MqttQos.atMostOnce);

    // Asansör durumu
    _client!.subscribe('agrimind/elevator/status', MqttQos.atMostOnce);
    _client!.subscribe('agrimind/elevator/position', MqttQos.atMostOnce);
    // Fan ve Heater durumu
    _client!.subscribe('agrimind/fan/status', MqttQos.atMostOnce);
    _client!.subscribe('agrimind/heater/status', MqttQos.atMostOnce);
    // Brain yanıtları ve alertler
    _client!.subscribe('agrimind/brain/response', MqttQos.atMostOnce);
    _client!.subscribe('agrimind/brain/alert', MqttQos.atMostOnce);
    _client!.subscribe('agrimind/agent/+/alert', MqttQos.atMostOnce);

    // Mesajları dinle
    _client!.updates!.listen(_onMessage);
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final payload = MqttPublishPayload.bytesToStringAsString(
          (message.payload as MqttPublishMessage).payload.message);

      try {
        final json = jsonDecode(payload);

        if (topic == 'agrimind/sensors/data') {
          _sensorController.add(SensorData.fromJson(json));
        } else if (topic == 'agrimind/sensors/cabin') {
          // Kabin sensör verisi - stream'e ekle
          _cabinSensorController.add(json);
        } else if (topic.startsWith('agrimind/elevator/')) {
          _elevatorController.add(ElevatorStatus.fromJson(json));
        } else if (topic == 'agrimind/fan/status') {
          _fanStatusController.add(json);
        } else if (topic == 'agrimind/heater/status') {
          _heaterStatusController.add(json);
        } else if (topic == 'agrimind/brain/response') {
          _brainResponseController.add(json);
        } else if (topic.contains('/alert')) {
          _alertController.add(BrainAlert.fromJson(json));
        }
      } catch (e) {
        print('MQTT parse error: $e');
      }
    }
  }

  // Asansör komutu gönder
  void sendElevatorCommand(String cmd, {Map<String, dynamic>? params}) {
    if (_client == null || !_isConnected) return;

    final payload = jsonEncode({'cmd': cmd, ...?params});
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _client!.publishMessage(
      'agrimind/elevator/cmd',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }
  // Fan komutu gönder
  void sendFanCommand(String cmd, {Map<String, dynamic>? params}) {
    if (_client == null || !_isConnected) return;

    final payload = jsonEncode({'cmd': cmd, ...?params});
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _client!.publishMessage(
      'agrimind/fan/cmd',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  // Heater komutu gönder
  void sendHeaterCommand(String cmd) {
    if (_client == null || !_isConnected) return;

    final payload = jsonEncode({'cmd': cmd});
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _client!.publishMessage(
      'agrimind/heater/cmd',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }
  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
  }

  @override
  void dispose() {
    disconnect();
    _sensorController.close();
    _cabinSensorController.close();
    _elevatorController.close();
    _alertController.close();
    _brainResponseController.close();
    _fanStatusController.close();
    _heaterStatusController.close();
    super.dispose();
  }
}
