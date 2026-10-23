import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_pill.dart';
import '../widgets/cat_mark.dart';
import 'tab_detail_screen.dart';
import 'create_tab_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiClient api;
  const HomeScreen({super.key, required this.api});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<TabSummary>> _tabsFuture;

  @override
  void initState() {
    super.initState();
    _tabsFuture = widget.api.fetchTabs();
  }

    void _reload() {
    setState(() {
      _tabsFuture = widget.api.fetchTabs();
    });
  }

  Future<void> _openCreateTab() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateTabScreen(api: widget.api)),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CatMark(size: 24),
            SizedBox(width: 8),
            Text('Tabby', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              await widget.api.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => AuthScreen(api: widget.api)),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTab,
        label: const Text('New tab'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.surface,
      ),
      body: FutureBuilder<List<TabSummary>>(
        future: _tabsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          final tabs = snapshot.data ?? [];
          final owed = tabs.where((t) => t.yourBalance > 0).fold(0.0, (s, t) => s + t.yourBalance);
          final owe = tabs.where((t) => t.yourBalance < 0).fold(0.0, (s, t) => s + -t.yourBalance);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(child: _SummaryCard(label: "You're owed", value: owed, color: AppColors.teal)),
                      const SizedBox(width: 12),
                    Expanded(child: _SummaryCard(label: 'You owe', value: owe, color: AppColors.coral)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Your tabs', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (tabs.isEmpty) const _EmptyTabs() else ...tabs.map((t) => _TabRow(tab: t, api: widget.api)),
              ],
            ),
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
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.ink)),
            const SizedBox(height: 8),
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

class _TabRow extends StatelessWidget {
  final TabSummary tab;
  final ApiClient api;
  const _TabRow({required this.tab, required this.api});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TabDetailScreen(api: api, tabId: tab.id)),
          );
        },
        title: Text(tab.name, style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
        subtitle: Text('${tab.memberCount} people \u00b7 ${formatCurrency(tab.totalSpent)} spent'),
        trailing: tab.yourBalance.abs() < 0.01
            ? const Text('Settled', style: TextStyle(color: AppColors.ink, fontSize: 12))
            : BalancePill(value: tab.yourBalance),
      ),
    );
  }
}

class _EmptyTabs extends StatelessWidget {
  const _EmptyTabs();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text('\ud83d\udc08', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('No tabs yet', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Create one to start splitting expenses.'),
        ],
      ),
    );
  }
}
