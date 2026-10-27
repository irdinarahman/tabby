import '../models/models.dart';
import '../theme/app_theme.dart';
import 'api_client.dart';

class ActivityEvent {
  final bool isSettlement;
  final String text;
  final String tabName;
  final DateTime date; // date only
  final int seq;

  ActivityEvent({
    required this.isSettlement,
    required this.text,
    required this.tabName,
    required this.date,
    required this.seq,
  });
}

DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Builds a newest-first feed of expenses and settlements across every tab.
/// Fetches each tab once; fine for the handful of tabs a person has.
Future<List<ActivityEvent>> loadActivity(ApiClient api, List<TabSummary> tabs) async {
  final details = await Future.wait(tabs.map((t) => api.fetchTab(t.id)));
  final events = <ActivityEvent>[];
  var seq = 0;

  for (final tab in details) {
    final meId = tab.me?.id;
    String who(String id, {bool object = false}) {
      if (id == meId) return object ? 'you' : 'You';
      return tab.memberName(id);
    }

    for (final e in tab.expenses) {
      events.add(ActivityEvent(
        isSettlement: false,
        text: '${who(e.paidBy)} paid ${formatCurrency(e.amount)} for ${e.description}',
        tabName: tab.name,
        date: _dateOnly(e.date),
        seq: seq++,
      ));
    }
    for (final s in tab.settlements) {
      events.add(ActivityEvent(
        isSettlement: true,
        text: '${who(s.paidBy)} paid ${who(s.paidTo, object: true)} ${formatCurrency(s.amount)}',
        tabName: tab.name,
        date: _dateOnly(s.settledAt.toLocal()),
        seq: seq++,
      ));
    }
  }

  events.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : b.seq.compareTo(a.seq);
  });
  return events;
}
