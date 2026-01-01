import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_data.dart';
import '../models/elevator_status.dart';
import '../models/alert.dart';

class MqttService extends ChangeNotifier {
  static const String broker = '192.168.0.3';
  static const int port = 1883;
  static const String clientId = 'agrimind_flutter_app';

  MqttServerClient? _client;
  bool _isConnected = false;
  
  // Streams
  final _sensorController = StreamController<SensorData>.broadcast();
  final _elevatorController = StreamController<ElevatorStatus>.broadcast();
  final _alertController = StreamController<BrainAlert>.broadcast();
  final _brainResponseController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<SensorData> get sensorStream => _sensorController.stream;
  Stream<ElevatorStatus> get elevatorStream => _elevatorController.stream;
  Stream<BrainAlert> get alertStream => _alertController.stream;
  Stream<Map<String, dynamic>> get brainResponseStream => _brainResponseController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    _client = MqttServerClient(broker, clientId);
    _client!.port = port;
    _client!.keepAlivePeriod = 60;
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.logging(on: false);
    _client!.autoReconnect = true;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
    } catch (e) {
      print('MQTT Connection failed: $e');
      _client!.disconnect();
      _scheduleReconnect();
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
        } 
        else if (topic.startsWith('agrimind/elevator/')) {
          _elevatorController.add(ElevatorStatus.fromJson(json));
        }
        else if (topic == 'agrimind/brain/response') {
          _brainResponseController.add(json);
        }
        else if (topic.contains('/alert')) {
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

  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
  }

  @override
  void dispose() {
    disconnect();
    _sensorController.close();
    _elevatorController.close();
    _alertController.close();
    _brainResponseController.close();
    super.dispose();
  }
}
