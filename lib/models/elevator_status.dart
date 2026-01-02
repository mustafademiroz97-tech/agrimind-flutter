// Asansör durumu
class ElevatorStatus {
  final String status;
  final int position;
  final int rack;
  final bool moving;
  final bool homed;
  final bool autoScan;

  ElevatorStatus({
    required this.status,
    required this.position,
    required this.rack,
    required this.moving,
    required this.homed,
    required this.autoScan,
  });

  factory ElevatorStatus.fromJson(Map<String, dynamic> json) {
    // API yanıtı { elevator: {...}, status: 'ok' } şeklinde geliyor
    final elevatorData = json['elevator'] ?? json;
    return ElevatorStatus(
      status: elevatorData['status'] ?? 'unknown',
      position: elevatorData['position'] ?? 0,
      rack: elevatorData['rack'] ?? 1,
      moving: elevatorData['moving'] ?? false,
      homed: elevatorData['homed'] ?? false,
      autoScan: elevatorData['auto_scan'] ?? false,
    );
  }

  factory ElevatorStatus.empty() {
    return ElevatorStatus(
      status: 'unknown',
      position: 0,
      rack: 1,
      moving: false,
      homed: false,
      autoScan: false,
    );
  }
}
