import 'package:flutter/material.dart';

class SensorGauge extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final double min;
  final double max;
  final List<double> optimal;
  final IconData icon;
  final Color color;
  final int decimals;

  const SensorGauge({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.optimal,
    required this.icon,
    required this.color,
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isOptimal = value >= optimal[0] && value <= optimal[1];
    final isLow = value < optimal[0];
    final isHigh = value > optimal[1];
    
    Color statusColor;
    if (isOptimal) {
      statusColor = Colors.green;
    } else if ((isLow && value < min + (optimal[0] - min) * 0.5) ||
               (isHigh && value > optimal[1] + (max - optimal[1]) * 0.5)) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }

    final percentage = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              decimals > 0
                  ? value.toStringAsFixed(decimals)
                  : value.toInt().toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            // Mini gauge bar
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Optimal range marker
                Positioned(
                  left: (optimal[0] - min) / (max - min) * 100 - 1,
                  child: Container(
                    width: 2,
                    height: 6,
                    color: Colors.green.withOpacity(0.5),
                  ),
                ),
                Positioned(
                  right: (max - optimal[1]) / (max - min) * 100 - 1,
                  child: Container(
                    width: 2,
                    height: 6,
                    color: Colors.green.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${optimal[0].toInt()}-${optimal[1].toInt()} $unit',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
