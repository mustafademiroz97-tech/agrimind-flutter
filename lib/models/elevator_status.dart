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
    return ElevatorStatus(
      status: json['status'] ?? 'unknown',
      position: json['position'] ?? 0,
      rack: json['rack'] ?? 1,
      moving: json['moving'] ?? false,
      homed: json['homed'] ?? false,
      autoScan: json['auto_scan'] ?? false,
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
