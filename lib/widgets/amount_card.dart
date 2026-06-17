import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AmountCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const AmountCard({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'ru_RU');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Text(
              fmt.format(amount),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
