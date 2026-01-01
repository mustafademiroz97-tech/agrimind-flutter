// Alert modeli
import 'package:flutter/material.dart';

class BrainAlert {
  final String agent;
  final String time;
  final int? rack;
  final String severity;
  final int? healthScore;
  final String? disease;
  final String message;

  BrainAlert({
    required this.agent,
    required this.time,
    this.rack,
    required this.severity,
    this.healthScore,
    this.disease,
    required this.message,
  });

  Color get severityColor =>
      severity == 'HIGH' ? Colors.red : Colors.orange;

  IconData get severityIcon =>
      severity == 'HIGH' ? Icons.error : Icons.warning;

  factory BrainAlert.fromJson(Map<String, dynamic> json) {
    return BrainAlert(
      agent: json['agent'] ?? 'brain',
      time: json['time'] ?? '',
      rack: json['rack'],
      severity: json['severity'] ?? 'MEDIUM',
      healthScore: json['health_score'],
      disease: json['disease'],
      message: json['message'] ?? '',
    );
  }
}
