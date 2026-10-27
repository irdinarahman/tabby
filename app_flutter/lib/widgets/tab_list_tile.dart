import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'balance_pill.dart';

class TabListTile extends StatelessWidget {
  final TabSummary tab;
  final VoidCallback onTap;

  const TabListTile({super.key, required this.tab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tab.name,
                        style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${plural(tab.memberCount, 'person', 'people')} \u00b7 ${formatCurrency(tab.totalSpent)} spent',
                        style: const TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (tab.yourBalance.abs() < 0.01)
                  const Text(
                    'Settled',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
                  )
                else
                  BalancePill(value: tab.yourBalance),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
