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
  
  // Alertler
  final List<BrainAlert> _alerts = [];
  List<BrainAlert> get alerts => _alerts;
  
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
  
  // Bağlantı modunu değiştir
  void setConnectionMode(bool remote) {
    ApiService.setRemoteMode(remote);
    notifyListeners();
    refreshSensorData(); // Yeni sunucuyla test et
  }
  
  // Otomatik sunucu seç (local önce, yoksa remote)
  Future<void> autoSelectServer() async {
    // Önce local dene
    ApiService.setRemoteMode(false);
    try {
      await _api.getMetrics().timeout(const Duration(seconds: 3));
      _isConnected = true;
      notifyListeners();
      return;
    } catch (_) {}
    
    // Local başarısız, remote dene
    ApiService.setRemoteMode(true);
    try {
      await _api.getMetrics().timeout(const Duration(seconds: 5));
      _isConnected = true;
      notifyListeners();
      return;
    } catch (_) {
      _isConnected = false;
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

  // ============ SENSOR DATA ============
  Future<void> refreshSensorData() async {
    try {
      _sensorData = await _api.getMetrics();
      _isConnected = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      _error = 'Bağlantı hatası';
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

  String getImageUrl(String filename) => _api.getImageUrl(filename);
  String get videoFeedUrl => _api.videoFeedUrl;

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
    final success = await _api.sendElevatorCommand('go_to_rack', params: {'rack': rack});
    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));
      await refreshElevatorStatus();
    }
    return success;
  }

  Future<bool> moveElevator(String direction, {int steps = 500}) async {
    final cmd = direction == 'up' ? 'move_up' : 'move_down';
    return await _api.sendElevatorCommand(cmd, params: {'steps': steps});
  }

  Future<bool> stopElevator() async {
    return await _api.sendElevatorCommand('stop');
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
