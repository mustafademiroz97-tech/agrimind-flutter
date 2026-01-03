import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _growthData;
  bool _isLoading = true;
  String? _error;
  int _selectedRack = 1;

  @override
  void initState() {
    super.initState();
    _loadGrowthData();
  }

  Future<void> _loadGrowthData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.getGrowthSummary(_selectedRack);
      setState(() {
        _growthData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Row(
          children: [
            Icon(Icons.straighten, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Sanal Cetvel', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadGrowthData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Bir hata oluştu',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGrowthData,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_growthData == null || _growthData!.containsKey('error')) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Raf seçici
          _buildRackSelector(),
          const SizedBox(height: 20),

          // Ana yükseklik kartı
          _buildHeightCard(),
          const SizedBox(height: 16),

          // Işık durumu kartı
          _buildLightCard(),
          const SizedBox(height: 16),

          // Büyüme hızı kartı
          _buildGrowthRateCard(),
          const SizedBox(height: 16),

          // Hasat tahmini kartı
          _buildHarvestCard(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grass,
              color: Colors.greenAccent.withOpacity(0.3), size: 80),
          const SizedBox(height: 16),
          const Text(
            'Henüz büyüme verisi yok',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Bitki yüksekliği ölçümleri yapıldıkça\nburada görünecek.',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRackSelector() {
    return Row(
      children: List.generate(4, (index) {
        final rack = index + 1;
        final isSelected = rack == _selectedRack;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedRack = rack;
              });
              _loadGrowthData();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.greenAccent.withOpacity(0.2)
                    : const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.greenAccent : Colors.white12,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.layers,
                    color: isSelected ? Colors.greenAccent : Colors.white54,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Raf $rack',
                    style: TextStyle(
                      color: isSelected ? Colors.greenAccent : Colors.white54,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeightCard() {
    final height = _growthData?['current_height_cm'] ?? 0;
    final stage = _growthData?['light_analysis']?['stage_tr'] ?? 'Bilinmiyor';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withOpacity(0.15),
            Colors.tealAccent.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Cetvel ikonu
          Container(
            width: 60,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: RulerPainter(height.toDouble()),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bitki Yüksekliği',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$height',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        'cm',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🌱 $stage',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightCard() {
    final light = _growthData?['light_analysis'] ?? {};
    final distanceToLight = light['distance_from_light_cm'] ?? 0;
    final ppfd = light['ppfd'] ?? 0;
    final lightStatus = light['light_status'] ?? 'unknown';
    final warning = light['warning'];

    Color statusColor;
    IconData statusIcon;
    switch (lightStatus) {
      case 'optimal':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle;
        break;
      case 'excessive':
        statusColor = Colors.redAccent;
        statusIcon = Icons.warning;
        break;
      case 'insufficient':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.wb_sunny_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: statusColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Işık Durumu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(statusIcon, color: statusColor, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLightMetric(
                  'Işığa Mesafe',
                  '${distanceToLight.toStringAsFixed(0)} cm',
                  Icons.straighten,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLightMetric(
                  'PPFD',
                  '${ppfd.toStringAsFixed(0)}',
                  Icons.wb_sunny,
                ),
              ),
            ],
          ),
          if (warning != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLightMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthRateCard() {
    final rate24h = _growthData?['growth_rate_24h'];
    final rate7d = _growthData?['growth_rate_7d'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blueAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Büyüme Hızı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRateChip(
                  'Son 24 Saat',
                  rate24h != null
                      ? '${rate24h.toStringAsFixed(2)} cm/gün'
                      : '-',
                  Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRateChip(
                  'Son 7 Gün',
                  rate7d != null ? '${rate7d.toStringAsFixed(2)} cm/gün' : '-',
                  Colors.purpleAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestCard() {
    final days = _growthData?['estimated_harvest_days'];

    Color cardColor;
    String message;
    IconData icon;

    if (days == null) {
      cardColor = Colors.grey;
      message = 'Yeterli veri yok';
      icon = Icons.hourglass_empty;
    } else if (days == 0) {
      cardColor = Colors.greenAccent;
      message = 'HASAT ZAMANI! 🎉';
      icon = Icons.celebration;
    } else if (days <= 3) {
      cardColor = Colors.orangeAccent;
      message = '$days gün sonra hasat!';
      icon = Icons.timer;
    } else {
      cardColor = Colors.blueAccent;
      message = 'Tahmini $days gün';
      icon = Icons.calendar_today;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor.withOpacity(0.15),
            cardColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: cardColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hasat Tahmini',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (days != null && days > 0)
            Column(
              children: [
                Text(
                  '$days',
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'gün',
                  style: TextStyle(color: cardColor.withOpacity(0.7)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// Küçük cetvel çizici
class RulerPainter extends CustomPainter {
  final double height;
  RulerPainter(this.height);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.5)
      ..strokeWidth = 1;

    // Arka plan çizgileri
    for (int i = 0; i <= 30; i += 5) {
      final y = size.height - (i / 30 * size.height);
      final lineWidth = i % 10 == 0 ? size.width * 0.5 : size.width * 0.3;
      canvas.drawLine(
        Offset(0, y),
        Offset(lineWidth, y),
        paint,
      );
    }

    // Mevcut yükseklik
    if (height > 0 && height <= 30) {
      final currentY = size.height - (height / 30 * size.height);
      final highlightPaint = Paint()
        ..color = Colors.greenAccent
        ..strokeWidth = 3;
      canvas.drawLine(
        Offset(0, currentY),
        Offset(size.width, currentY),
        highlightPaint,
      );

      // Bitki simgesi
      final plantPaint = Paint()..color = Colors.greenAccent;
      canvas.drawCircle(
        Offset(size.width * 0.7, currentY),
        4,
        plantPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
