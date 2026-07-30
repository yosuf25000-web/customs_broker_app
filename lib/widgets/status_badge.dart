import 'package:flutter/material.dart';
import '../models/declaration.dart';

class StatusBadge extends StatelessWidget {
  final DeclarationStatus status;
  final String label;
  const StatusBadge({super.key, required this.status, required this.label});

  Color get _color {
    switch (status) {
      case DeclarationStatus.draft:
        return Colors.grey;
      case DeclarationStatus.calculated:
        return Colors.orange;
      case DeclarationStatus.approved:
        return Colors.green;
      case DeclarationStatus.cancelled:
        return Colors.red;
      case DeclarationStatus.unknown:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
