import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ElevatorControls extends StatelessWidget {
  const ElevatorControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final status = provider.elevatorStatus;
        
        return Column(
          children: [
            // Raf butonları
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Raf 4 (en üst)
                  _buildRackButton(context, 4, status.rack, status.moving, provider),
                  const SizedBox(height: 4),
                  _buildRackButton(context, 3, status.rack, status.moving, provider),
                  const SizedBox(height: 4),
                  _buildRackButton(context, 2, status.rack, status.moving, provider),
                  const SizedBox(height: 4),
                  // Raf 1 (en alt - home)
                  _buildRackButton(context, 1, status.rack, status.moving, provider),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Hareket kontrolleri
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMoveButton(
                  context,
                  Icons.arrow_upward,
                  'Yukarı',
                  () => provider.moveElevator('up'),
                  status.moving,
                ),
                const SizedBox(width: 8),
                _buildMoveButton(
                  context,
                  Icons.stop,
                  'Dur',
                  () => provider.stopElevator(),
                  false,
                  isStop: true,
                ),
                const SizedBox(width: 8),
                _buildMoveButton(
                  context,
                  Icons.arrow_downward,
                  'Aşağı',
                  () => provider.moveElevator('down'),
                  status.moving,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRackButton(
    BuildContext context,
    int rack,
    int currentRack,
    bool moving,
    AppProvider provider,
  ) {
    final isActive = currentRack == rack;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: moving ? null : () => provider.goToRack(rack),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          foregroundColor: isActive
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive) ...[
              const Icon(Icons.location_on, size: 14),
              const SizedBox(width: 4),
            ],
            Text('Raf $rack'),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    bool disabled, {
    bool isStop = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isStop
            ? Colors.red.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: disabled && !isStop ? null : onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: isStop
                  ? Colors.red
                  : (disabled ? Colors.grey : null),
            ),
          ),
        ),
      ),
    );
  }
}
