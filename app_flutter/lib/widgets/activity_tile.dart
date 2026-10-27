import 'package:flutter/material.dart';
import '../services/activity_service.dart';
import '../theme/app_theme.dart';

class ActivityTile extends StatelessWidget {
  final ActivityEvent event;
  final bool last;

  const ActivityTile({super.key, required this.event, this.last = false});

  @override
  Widget build(BuildContext context) {
    final settled = event.isSettlement;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: settled ? AppColors.tealTint : AppColors.amberTint,
            ),
            child: Icon(
              settled ? Icons.check_rounded : Icons.receipt_long_outlined,
              size: 17,
              color: settled ? AppColors.teal : AppColors.rust,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '${event.tabName} \u00b7 ${formatDate(event.date)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
