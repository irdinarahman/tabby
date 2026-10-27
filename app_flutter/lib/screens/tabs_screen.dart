import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../widgets/async_body.dart';
import '../widgets/empty_state.dart';
import '../widgets/tab_list_tile.dart';
import 'create_tab_screen.dart';
import 'tab_detail_screen.dart';

class TabsScreen extends StatelessWidget {
  final ApiClient api;
  const TabsScreen({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsyncBody<List<TabSummary>>(
        load: api.fetchTabs,
        builder: (context, tabs) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tabs',
                      style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 22),
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
              const SizedBox(height: 10),
              if (tabs.isEmpty)
                const EmptyState(title: 'No tabs yet', body: 'Create one to start splitting expenses.')
              else
                for (final t in tabs)
                  TabListTile(
                    tab: t,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TabDetailScreen(api: api, tabId: t.id)),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
