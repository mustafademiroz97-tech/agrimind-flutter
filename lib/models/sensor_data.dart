// Sensör verileri modeli
class SensorData {
  final CabinData cabin;
  final WaterData water;
  final List<RackData> racks;
  final String time;

  SensorData({
    required this.cabin,
    required this.water,
    required this.racks,
    required this.time,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    // racks hem List hem de Map olarak gelebilir
    List<RackData> racksList = [];
    final racksData = json['racks'];
    if (racksData is List) {
      racksList = racksData.map((r) => RackData.fromJson(r)).toList();
    } else if (racksData is Map) {
      // Map ise key'leri kullanarak RackData oluştur
      racksData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          racksList.add(RackData.fromJson({...value, 'id': key}));
        }
      });
    }

    return SensorData(
      cabin: CabinData.fromJson(json['cabin'] ?? {}),
      water: WaterData.fromJson(json['water'] ?? {}),
      racks: racksList,
      time: json['ts']?.toString() ?? json['time']?.toString() ?? '',
    );
  }

  factory SensorData.empty() {
    return SensorData(
      cabin: CabinData.empty(),
      water: WaterData.empty(),
      racks: List.generate(4, (i) => RackData.empty(i + 1)),
      time: '',
    );
  }
}

class CabinData {
  final double temperature;
  final double humidity;
  final int co2;

  CabinData({
    required this.temperature,
    required this.humidity,
    required this.co2,
  });

  factory CabinData.fromJson(Map<String, dynamic> json) {
    return CabinData(
      temperature: (json['temperature'] ?? json['temp'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      co2: (json['co2'] ?? json['light'] ?? 0).toInt(),
    );
  }

  factory CabinData.empty() {
    return CabinData(temperature: 0, humidity: 0, co2: 0);
  }
}

class WaterData {
  final double ph;
  final double ec;
  final double temperature;
  final int level;

  WaterData({
    required this.ph,
    required this.ec,
    required this.temperature,
    required this.level,
  });

  factory WaterData.fromJson(Map<String, dynamic> json) {
    return WaterData(
      ph: (json['ph'] ?? 0).toDouble(),
      ec: (json['ec'] ?? 0).toDouble(),
      temperature: (json['temperature'] ?? json['temp'] ?? 0).toDouble(),
      level: (json['level'] ?? 0).toInt(),
    );
  }

  factory WaterData.empty() {
    return WaterData(ph: 0, ec: 0, temperature: 0, level: 0);
  }
}

class RackData {
  final int id;
  final double temperature;
  final double humidity;
  final int light;
  final int healthScore;

  RackData({
    required this.id,
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.healthScore,
  });

  factory RackData.fromJson(Map<String, dynamic> json) {
    return RackData(
      id: json['id'] ?? 0,
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      light: (json['light'] ?? 0).toInt(),
      healthScore: (json['health_score'] ?? 0).toInt(),
    );
  }

  factory RackData.empty(int id) {
    return RackData(
      id: id,
      temperature: 0,
      humidity: 0,
      light: 0,
      healthScore: 0,
    );
  }
}
