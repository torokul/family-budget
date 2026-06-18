import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/group.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final double spent;
  final double plan;
  final int categoryCount;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.group,
    required this.spent,
    required this.plan,
    required this.categoryCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt      = NumberFormat('#,##0', 'ru_RU');
    final hasPlan  = plan > 0;
    final progress = hasPlan ? (spent / plan).clamp(0.0, 1.0) : 0.0;
    final pct      = hasPlan ? (spent / plan * 100).round() : null;
    final over     = hasPlan && spent > plan;

    Color barColor;
    if (!hasPlan)       barColor = group.color.withAlpha(180);
    else if (over)      barColor = const Color(0xFFD32F2F);
    else if (pct! > 80) barColor = const Color(0xFFF57F17);
    else                barColor = const Color(0xFF2E7D32);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: group.color,
              child: Row(children: [
                Icon(group.icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(group.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (pct != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$pct%',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ]),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Факт', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      Text(
                        '${fmt.format(spent)} KGS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: over ? const Color(0xFFD32F2F) : Colors.black87,
                        ),
                      ),
                    ]),
                  ),
                  if (hasPlan)
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('План', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      Text('${fmt.format(plan)} KGS',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    ]),
                ]),
                if (hasPlan) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text('$categoryCount статей',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
