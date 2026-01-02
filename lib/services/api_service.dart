import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import '../models/chat_message.dart';
import '../models/elevator_status.dart';
import '../models/report.dart';

class ApiService {
  // URL'ler artık sadece remote olacak şekilde sabitlendi.
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
  static const Duration timeout = Duration(seconds: 15); // Timeout biraz artırıldı.

  // ============ SENSORS ============
  Future<SensorData> getMetrics() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/metrics'))
          .timeout(timeout);
      
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

  String getImageUrl(String filename) {
    return '$baseUrl/gallery_files/$filename';
  }

  String get videoFeedUrl => '$baseUrl/video_feed';

  // ============ ELEVATOR ============
  // Asansör move komutu (up/down/rack)
  Future<bool> elevatorMove({String? direction, int? rack, int steps = 500}) async {
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
  Future<bool> sendElevatorCommand(String cmd, {Map<String, dynamic>? params}) async {
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
      final response = await http
          .get(Uri.parse('$baseUrl/api/ptz/home'))
          .timeout(timeout);
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
      return ReportStats(hourlyCount: 0, dailyCount: 0, weeklyCount: 0, monthlyCount: 0);
    } catch (e) {
      print('API Error (report stats): $e');
      rethrow;
    }
  }

  Future<List<HourlyReport>> getHourlyReports() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/reports/hourly'))
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((r) => HourlyReport.fromJson(r)).toList();
        }
      }
      return [];
    } catch (e) {
      print('API Error (hourly): $e');
      return [];
    }
  }

  Future<List<DailyReport>> getDailyReports() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/reports/daily'))
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((r) => DailyReport.fromJson(r)).toList();
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

  // ============ HEALTH ============
  Future<Map<String, dynamic>> getHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Health check failed');
    } catch (e) {
      print('API Error (health): $e');
      rethrow;
    }
  }
}
// Update Thu  1 Jan 23:49:37 +03 2026
