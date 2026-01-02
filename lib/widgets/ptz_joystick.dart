import 'package:flutter/material.dart';

class PtzJoystick extends StatelessWidget {
  final Function(String direction) onMove;
  final VoidCallback onStop;
  final VoidCallback? onReturnHome;  // Manuel home'a dön butonu

  const PtzJoystick({
    super.key,
    required this.onMove,
    required this.onStop,
    this.onReturnHome,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border.all(color: Colors.grey[700]!),
            ),
          ),
          
          // Up
          Positioned(
            top: 8,
            child: _buildDirectionButton(
              Icons.arrow_upward,
              'up',
            ),
          ),
          
          // Down
          Positioned(
            bottom: 8,
            child: _buildDirectionButton(
              Icons.arrow_downward,
              'down',
            ),
          ),
          
          // Left
          Positioned(
            left: 8,
            child: _buildDirectionButton(
              Icons.arrow_back,
              'left',
            ),
          ),
          
          // Right
          Positioned(
            right: 8,
            child: _buildDirectionButton(
              Icons.arrow_forward,
              'right',
            ),
          ),
          
          // Center - Home button (yeşil) - Manuel home'a dön
          GestureDetector(
            onTap: onReturnHome ?? onStop,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withValues(alpha: 0.2),
                border: Border.all(color: Colors.green),
              ),
              child: const Icon(Icons.home, color: Colors.green, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(IconData icon, String direction) {
    return GestureDetector(
      onTapDown: (_) => onMove(direction),
      onTapUp: (_) => onStop(),  // Sadece stop, home'a gitme
      onTapCancel: onStop,  // Sadece stop, home'a gitme
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.withValues(alpha: 0.2),
          border: Border.all(color: Colors.blue),
        ),
        child: Icon(icon, color: Colors.blue, size: 20),
      ),
    );
  }
}
