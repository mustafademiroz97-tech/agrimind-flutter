import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import '../models/chat_message.dart';
import '../models/elevator_status.dart';
import '../models/report.dart';

class ApiService {
  // URL'ler artık sadece remote olacak şekilde sabitlendi.
  // Production URL
  static const String _baseUrl = 'https://api.neuraponic.com';

  static String get baseUrl => _baseUrl;
  static bool get isRemote => true; // Her zaman remote moddayız.

  // URL'i manuel değiştirme fonksiyonları kaldırıldı veya etkisiz hale getirildi.
  static void setRemoteMode(bool remote) {
    // Bu fonksiyon artık bir işe yaramayacak.
  }

  static void setBaseUrl(String url) {
    // Bu fonksiyon artık bir işe yaramayacak.
  }

  // Timeout süresi
  static const Duration timeout =
      Duration(seconds: 15); // Timeout biraz artırıldı.

  // ============ SENSORS ============
  Future<SensorData> getMetrics() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/metrics')).timeout(timeout);

      if (response.statusCode == 200) {
        return SensorData.fromJson(jsonDecode(response.body));
      }
      throw Exception('Metrics fetch failed: ${response.statusCode}');
    } catch (e) {
      print('API Error (metrics): $e');
      rethrow;
    }
  }

  // ============ BRAIN ============
  Future<BrainResponse> askBrain(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/brain/ask'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 30)); // Brain için daha uzun timeout

      return BrainResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('API Error (brain): $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBrainMemory() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/brain/memory'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Memory fetch failed');
    } catch (e) {
      print('API Error (memory): $e');
      rethrow;
    }
  }

  // ============ GALLERY ============
  Future<List<String>> getGallery({int limit = 60}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/gallery?limit=$limit'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return List<String>.from(jsonDecode(response.body));
      }
      throw Exception('Gallery fetch failed');
    } catch (e) {
      print('API Error (gallery): $e');
      rethrow;
    }
  }

  Future<bool> deleteGalleryImage(String filename) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/api/gallery/$filename'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('API Error (delete image): $e');
      return false;
    }
  }

  String getImageUrl(String filename) {
    return '$baseUrl/gallery_files/$filename';
  }

  String get videoFeedUrl => '$baseUrl/video_feed';

  // ============ ANALYSES ============
  Future<List<Map<String, dynamic>>> getAnalyses({int limit = 30}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/agent/camera/analyses?limit=$limit'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('API Error (analyses): $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLastAnalysis() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/agent/camera/last_analysis'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('API Error (last_analysis): $e');
      return null;
    }
  }

  // ============ ELEVATOR ============
  // Asansör move komutu (up/down/rack)
  Future<bool> elevatorMove(
      {String? direction, int? rack, int steps = 500}) async {
    try {
      final body = <String, dynamic>{};
      if (rack != null) {
        body['rack'] = rack;
      } else if (direction != null) {
        body['direction'] = direction;
        body['steps'] = steps;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/elevator/move'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('API Error (elevator move): $e');
      return false;
    }
  }

  // Belirli rafa git (GET endpoint)
  Future<bool> elevatorGoToRack(int rack) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/elevator/go_to_rack/$rack'))
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      print('API Error (elevator go_to_rack): $e');
      return false;
    }
  }

  // Asansörü durdur
  Future<bool> elevatorStop() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/elevator/stop'))
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      print('API Error (elevator stop): $e');
      return false;
    }
  }

  // Tüm rafları tara
  Future<bool> elevatorScanAll() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/elevator/scan'))
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      print('API Error (elevator scan): $e');
      return false;
    }
  }

  // Eski API (uyumluluk için)
  Future<bool> sendElevatorCommand(String cmd,
      {Map<String, dynamic>? params}) async {
    switch (cmd) {
      case 'go_to_rack':
        return elevatorGoToRack(params?['rack'] ?? 1);
      case 'move_up':
        return elevatorMove(direction: 'up', steps: params?['steps'] ?? 500);
      case 'move_down':
        return elevatorMove(direction: 'down', steps: params?['steps'] ?? 500);
      case 'stop':
        return elevatorStop();
      case 'scan_all':
        return elevatorScanAll();
      default:
        return false;
    }
  }

  Future<ElevatorStatus> getElevatorStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/elevator/status'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return ElevatorStatus.fromJson(jsonDecode(response.body));
      }
      return ElevatorStatus.empty();
    } catch (e) {
      print('API Error (elevator status): $e');
      return ElevatorStatus.empty();
    }
  }

  // ============ PTZ ============
  // PTZ kontrolü - GET /api/move/<direction>
  Future<bool> sendPtzCommand(String direction, {double speed = 0.5}) async {
    try {
      // Backend /api/move/<direction> şeklinde GET endpoint kullanıyor
      final response = await http
          .get(Uri.parse('$baseUrl/api/move/$direction'))
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('API Error (ptz): $e');
      return false;
    }
  }

  Future<bool> stopPtz() async {
    // Backend'de stop endpoint'i yok, hareket zaten 0.3s sonra duruyor
    return true;
  }

  // PTZ'yi home pozisyonuna döndür
  Future<bool> ptzGoHome() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/ptz/home')).timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      print('API Error (ptz home): $e');
      return false;
    }
  }

  // Mevcut PTZ pozisyonunu home olarak kaydet
  Future<bool> ptzSaveHome() async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/api/ptz/save_home'))
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      print('API Error (ptz save home): $e');
      return false;
    }
  }

  // Asansörü son hedef rafa döndür (override sonrası)
  Future<bool> elevatorReturnToTarget() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/elevator/return_to_target'))
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      print('API Error (elevator return): $e');
      return false;
    }
  }

  // ============ CAPTURE ============
  Future<Map<String, dynamic>?> capturePhoto() async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/api/capture'))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('API Error (capture): $e');
      return null;
    }
  }

  // ============ REPORTS ============
  Future<ReportStats> getReportStats() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/reports/stats'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return ReportStats.fromJson(jsonDecode(response.body));
      }
      return ReportStats(
          hourlyCount: 0, dailyCount: 0, weeklyCount: 0, monthlyCount: 0);
    } catch (e) {
      print('API Error (report stats): $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getHourlyReports({int limit = 24}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/reports/hourly?limit=$limit'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      print('API Error (hourly): $e');
      return [];
    }
  }

  Future<List<dynamic>> getDailyReports({int limit = 14}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/reports/daily?limit=$limit'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      print('API Error (daily): $e');
      return [];
    }
  }

  Future<List<dynamic>> getWeeklyReports() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/reports/weekly'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMonthlyReports() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/reports/monthly'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ============ YAZILI RAPORLAR (Brain) ============
  Future<List<dynamic>> getWrittenReports({int limit = 30}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/brain/reports?limit=$limit'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reports'] ?? [];
      }
      return [];
    } catch (e) {
      print('API Error (written reports): $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> generateDailyReport({String? date}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/brain/reports/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'date': date}),
          )
          .timeout(
              const Duration(seconds: 60)); // Rapor oluşturma uzun sürebilir

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Report generation failed');
    } catch (e) {
      print('API Error (generate report): $e');
      rethrow;
    }
  }

  // ============ HEALTH ============
  Future<Map<String, dynamic>> getHealth() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/health')).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Health check failed');
    } catch (e) {
      print('API Error (health): $e');
      rethrow;
    }
  }

  // ============ GROWTH TRACKING (SANAL CETVEL) ============
  Future<Map<String, dynamic>> getGrowthSummary(int rackId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/growth/summary/$rackId'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Growth summary fetch failed');
    } catch (e) {
      print('API Error (growth summary): $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAllRacksGrowth() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/growth/all')).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('All racks growth fetch failed');
    } catch (e) {
      print('API Error (all growth): $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> recordGrowth(
      int rack, double heightCm, String source) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/growth/record'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'rack': rack,
              'height_cm': heightCm,
              'source': source,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Growth record failed');
    } catch (e) {
      print('API Error (record growth): $e');
      rethrow;
    }
  }

  // ============ LIGHT ANALYSIS ============
  Future<Map<String, dynamic>> analyzePlantLight(
      double heightCm, int rackId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/light/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'plant_height_cm': heightCm,
              'rack_id': rackId,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Light analysis failed');
    } catch (e) {
      print('API Error (light analyze): $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLightCalibration() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/light/calibration'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Light calibration fetch failed');
    } catch (e) {
      print('API Error (light calibration): $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateLightCalibration(
      List<Map<String, dynamic>> measurementPoints) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/light/calibration'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'measurement_points': measurementPoints,
              'calibration_date':
                  DateTime.now().toIso8601String().split('T')[0],
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Calibration update failed');
    } catch (e) {
      print('API Error (update calibration): $e');
      rethrow;
    }
  }

  // ============ SETTINGS ============
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/settings')).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('API Error (get settings): $e');
      return null;
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/settings'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(settings),
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('API Error (update settings): $e');
      return false;
    }
  }

  // ============ DOSING (Manual Pumps) ============
  Future<bool> doPump(String pumpId, int ml) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/dose'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'pump': pumpId,
              'ml': ml,
            }),
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('API Error (dose): $e');
      return false;
    }
  }

  // ============ DEVICE CONTROL ============
  Future<bool> toggleDevice(String device, bool state) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/device/$device'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'state': state}),
          )
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('API Error (device control): $e');
      return false;
    }
  }

  Future<Map<String, bool>> getDeviceStates() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/devices')).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, bool>.from(data);
      }
      return {};
    } catch (e) {
      print('API Error (get devices): $e');
      return {};
    }
  }
}
