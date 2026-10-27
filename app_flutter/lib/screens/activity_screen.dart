import 'package:flutter/material.dart';
import '../services/activity_service.dart';
import '../services/api_client.dart';
import '../widgets/activity_tile.dart';
import '../widgets/async_body.dart';
import '../widgets/empty_state.dart';

class ActivityScreen extends StatelessWidget {
  final ApiClient api;
  const ActivityScreen({super.key, required this.api});

  Future<List<ActivityEvent>> _load() async {
    final tabs = await api.fetchTabs();
    return loadActivity(api, tabs);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsyncBody<List<ActivityEvent>>(
        load: _load,
        builder: (context, events) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const Text(
                'Activity',
                style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 22),
              ),
              const SizedBox(height: 8),
              if (events.isEmpty)
                const EmptyState(title: 'No activity yet', body: 'Expenses and settlements will show up here.')
              else
                for (var i = 0; i < events.length; i++)
                  ActivityTile(event: events[i], last: i == events.length - 1),
            ],
          );
        },
      ),
    );
  }
}
