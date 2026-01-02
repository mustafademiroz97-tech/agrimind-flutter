import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class RackCard extends StatelessWidget {
  final RackData rack;

  const RackCard({super.key, required this.rack});

  @override
  Widget build(BuildContext context) {
    final healthColor = _getHealthColor(rack.healthScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🌿 Raf ${rack.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: healthColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, size: 12, color: healthColor),
                      const SizedBox(width: 4),
                      Text(
                        '${rack.healthScore}',
                        style: TextStyle(
                          color: healthColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetricRow(Icons.thermostat, 'Sıcaklık',
                      '${rack.temperature.toStringAsFixed(1)}°C'),
                  _buildMetricRow(Icons.water_drop, 'Nem',
                      '${rack.humidity.toStringAsFixed(0)}%'),
                  _buildMetricRow(
                      Icons.light_mode, 'Işık', '${rack.light} lux'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey))),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Color _getHealthColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
