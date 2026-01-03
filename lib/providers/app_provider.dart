import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/chat_message.dart';
import '../models/elevator_status.dart';
import '../models/alert.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // Sensör verileri
  SensorData _sensorData = SensorData.empty();
  SensorData get sensorData => _sensorData;

  // Asansör durumu
  ElevatorStatus _elevatorStatus = ElevatorStatus.empty();
  ElevatorStatus get elevatorStatus => _elevatorStatus;

  // Chat mesajları
  final List<ChatMessage> _chatMessages = [];
  List<ChatMessage> get chatMessages => _chatMessages;

  // Galeri
  List<String> _galleryImages = [];
  List<String> get galleryImages => _galleryImages;

  // Analizler
  List<Map<String, dynamic>> _analyses = [];
  List<Map<String, dynamic>> get analyses => _analyses;

  // Alertler
  final List<BrainAlert> _alerts = [];
  List<BrainAlert> get alerts => _alerts;

  // Cihaz durumları (light, fan, pump, heater, cooler)
  Map<String, bool> _deviceStates = {};
  Map<String, bool> get deviceStates => _deviceStates;

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isChatLoading = false;
  bool get isChatLoading => _isChatLoading;

  // Bağlantı durumu
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Remote/Local mod
  bool get isRemoteMode => ApiService.isRemote;
  String get currentServerUrl => ApiService.baseUrl;

  String? _error;
  String? get error => _error;

  Timer? _refreshTimer;

  AppProvider() {
    _startPeriodicRefresh();
    _loadInitialData();
  }

  // Bağlantı modunu değiştir - artık sadece remote mod kullanılıyor
  void setConnectionMode(bool remote) {
    notifyListeners();
    refreshSensorData();
  }

  // Sunucu bağlantısını test et
  Future<void> autoSelectServer() async {
    _error = null;

    try {
      debugPrint('Testing API: ${ApiService.baseUrl}');
      await _api.getMetrics().timeout(const Duration(seconds: 15));
      _isConnected = true;
      _error = null;
      debugPrint('API connection successful');
      notifyListeners();
    } catch (e) {
      debugPrint('API connection failed: $e');
      _isConnected = false;
      _error = 'API bağlantısı başarısız: $e';
      notifyListeners();
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      refreshSensorData();
    });
  }

  Future<void> _loadInitialData() async {
    await autoSelectServer(); // Otomatik sunucu seç
    await refreshSensorData();
    await refreshGallery();
    await refreshElevatorStatus();
  }

  // HTTP Polling başlat (MQTT yerine)
  void startPolling() {
    // Zaten constructor'da başlatılıyor ama explicit çağrı için
    if (_refreshTimer == null || !_refreshTimer!.isActive) {
      _startPeriodicRefresh();
    }
    _loadInitialData();
  }

  // ============ SENSOR DATA ============
  Future<void> refreshSensorData() async {
    try {
      _sensorData = await _api.getMetrics();
      _isConnected = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      _error = 'API Hatası: $e';
      debugPrint('refreshSensorData error: $e');
      notifyListeners();
    }
  }

  void updateSensorData(SensorData data) {
    _sensorData = data;
    notifyListeners();
  }

  // ============ CHAT ============
  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Kullanıcı mesajını ekle
    _chatMessages.add(ChatMessage(text: message, isUser: true));
    _isChatLoading = true;
    notifyListeners();

    try {
      final response = await _api.askBrain(message);

      if (response.isSuccess && response.answer != null) {
        _chatMessages.add(ChatMessage(
          text: response.answer!,
          isUser: false,
          memoryStats: response.memoryStats,
        ));
      } else {
        _chatMessages.add(ChatMessage(
          text: response.message ?? 'Bir hata oluştu',
          isUser: false,
        ));
      }
    } catch (e) {
      _chatMessages.add(ChatMessage(
        text: 'Bağlantı hatası: $e',
        isUser: false,
      ));
    } finally {
      _isChatLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _chatMessages.clear();
    notifyListeners();
  }

  // ============ GALLERY ============
  Future<void> refreshGallery({int limit = 60}) async {
    try {
      _galleryImages = await _api.getGallery(limit: limit);
      notifyListeners();
    } catch (e) {
      print('Gallery error: $e');
    }
  }

  Future<bool> deleteGalleryImage(String filename) async {
    final success = await _api.deleteGalleryImage(filename);
    if (success) {
      _galleryImages.remove(filename);
      notifyListeners();
    }
    return success;
  }

  String getImageUrl(String filename) => _api.getImageUrl(filename);
  String get videoFeedUrl => _api.videoFeedUrl;

  // ============ ANALYSES ============
  Future<void> refreshAnalyses({int limit = 30}) async {
    try {
      _analyses = await _api.getAnalyses(limit: limit);
      notifyListeners();
    } catch (e) {
      print('Analyses error: $e');
    }
  }

  // ============ ELEVATOR ============
  Future<void> refreshElevatorStatus() async {
    try {
      _elevatorStatus = await _api.getElevatorStatus();
      notifyListeners();
    } catch (e) {
      print('Elevator status error: $e');
    }
  }

  Future<bool> goToRack(int rack) async {
    final success =
        await _api.sendElevatorCommand('go_to_rack', params: {'rack': rack});
    if (success) {
      // Hareket başladı - düzenli durum güncellemesi yap
      _pollElevatorUntilStopped();
    }
    return success;
  }

  // Asansör duruncaya kadar durumu güncelle
  void _pollElevatorUntilStopped() async {
    for (int i = 0; i < 30; i++) { // Max 30 saniye
      await Future.delayed(const Duration(seconds: 1));
      await refreshElevatorStatus();
      if (!_elevatorStatus.moving) break;
    }
  }

  Future<bool> moveElevator(String direction, {int steps = 500}) async {
    final cmd = direction == 'up' ? 'move_up' : 'move_down';
    final success = await _api.sendElevatorCommand(cmd, params: {'steps': steps});
    if (success) {
      _pollElevatorUntilStopped();
    }
    return success;
  }

  Future<bool> stopElevator() async {
    final success = await _api.sendElevatorCommand('stop');
    if (success) {
      await Future.delayed(const Duration(milliseconds: 300));
      await refreshElevatorStatus();
    }
    return success;
  }

  Future<bool> scanAllRacks() async {
    return await _api.sendElevatorCommand('scan_all');
  }

  void updateElevatorStatus(ElevatorStatus status) {
    _elevatorStatus = status;
    notifyListeners();
  }

  // ============ PTZ ============
  Future<void> movePtz(String direction) async {
    await _api.sendPtzCommand(direction);
  }

  Future<void> stopPtz() async {
    await _api.stopPtz();
  }

  Future<void> ptzGoHome() async {
    await _api.ptzGoHome();
  }

  Future<void> ptzSaveHome() async {
    await _api.ptzSaveHome();
  }

  // ============ CAPTURE ============
  Future<Map<String, dynamic>?> capturePhoto() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _api.capturePhoto();
      await refreshGallery();
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ ALERTS ============
  void addAlert(BrainAlert alert) {
    _alerts.insert(0, alert);
    if (_alerts.length > 50) {
      _alerts.removeLast();
    }
    notifyListeners();
  }

  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  // ============ DEVICE CONTROL ============
  Future<void> loadDeviceStates() async {
    try {
      _deviceStates = await _api.getDeviceStates();
      notifyListeners();
    } catch (e) {
      debugPrint('loadDeviceStates error: $e');
    }
  }

  Future<bool> toggleDevice(String device, bool state) async {
    try {
      final success = await _api.toggleDevice(device, state);
      if (success) {
        _deviceStates[device] = state;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('toggleDevice error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
