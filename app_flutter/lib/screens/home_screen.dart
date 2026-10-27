import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/activity_service.dart';
import '../services/api_client.dart';
import '../services/current_user.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_tile.dart';
import '../widgets/async_body.dart';
import '../widgets/cat_mark.dart';
import '../widgets/empty_state.dart';
import '../widgets/tab_list_tile.dart';
import 'create_tab_screen.dart';
import 'tab_detail_screen.dart';

class _HomeData {
  final List<TabSummary> tabs;
  final List<ActivityEvent> events;
  _HomeData(this.tabs, this.events);
}

class HomeScreen extends StatelessWidget {
  final ApiClient api;
  final VoidCallback onSeeAllActivity;

  const HomeScreen({super.key, required this.api, required this.onSeeAllActivity});

  Future<_HomeData> _load() async {
    final tabs = await api.fetchTabs();
    final events = await loadActivity(api, tabs);
    return _HomeData(tabs, events);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsyncBody<_HomeData>(
        load: _load,
        builder: (context, data) {
          final owed = data.tabs.where((t) => t.yourBalance > 0.01).fold(0.0, (s, t) => s + t.yourBalance);
          final owe = data.tabs.where((t) => t.yourBalance < -0.01).fold(0.0, (s, t) => s - t.yourBalance);
          final name = CurrentUser.instance.name ?? 'there';
          final first = name.split(' ').first;
          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
          final recent = data.events.take(4).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  const CatMark(size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Tabby',
                    style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.amber,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '${_greeting()}, $first \u{1F43E}',
                style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 22),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _SummaryCard(label: 'You\u2019re owed', value: owed, color: AppColors.teal)),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(label: 'You owe', value: owe, color: AppColors.coral)),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your tabs',
                      style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CreateTabScreen(api: api)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New tab'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (data.tabs.isEmpty)
                const EmptyState(title: 'No tabs yet', body: 'Create one to start splitting expenses.')
              else
                for (final t in data.tabs)
                  TabListTile(
                    tab: t,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TabDetailScreen(api: api, tabId: t.id)),
                    ),
                  ),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recent activity',
                        style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    TextButton(onPressed: onSeeAllActivity, child: const Text('See all')),
                  ],
                ),
                for (var i = 0; i < recent.length; i++)
                  ActivityTile(event: recent[i], last: i == recent.length - 1),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCurrency(value),
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
