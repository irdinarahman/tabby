import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/current_user.dart';
import '../services/settlement_optimizer.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_pill.dart';
import '../widgets/cat_mark.dart';
import 'add_expense_screen.dart';

class TabDetailScreen extends StatefulWidget {
  final ApiClient api;
  final String tabId;
  const TabDetailScreen({super.key, required this.api, required this.tabId});

  @override
  State<TabDetailScreen> createState() => _TabDetailScreenState();
}

class _TabDetailScreenState extends State<TabDetailScreen> with SingleTickerProviderStateMixin {
  late Future<TabDetail> _future;
  late TabController _tabController;
  final _optimizer = SettlementOptimizer();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _future = widget.api.fetchTab(widget.tabId);
  }

    void _reload() {
    setState(() {
      _future = widget.api.fetchTab(widget.tabId);
    });
  }

  Future<void> _openAddExpense(TabDetail tab) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddExpenseScreen(api: widget.api, tab: tab)),
    );
    if (added == true) _reload();
  }

  Future<void> _markSettled(String from, String to, double amount) async {
    await widget.api.markSettled(tabId: widget.tabId, paidBy: from, paidTo: to, amount: amount);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<TabDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          final tab = snapshot.data!;
          final myMember = tab.members.where((m) => m.userId == CurrentUser.instance.id);
          final yourBalance = myMember.isNotEmpty ? (tab.balances[myMember.first.id] ?? 0.0) : 0.0;
          final plan = _optimizer.plan(tab.balances);
          final allSettled = tab.balances.values.every((v) => v.abs() < 0.01);

          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                pinned: true,
                title: Text(tab.name, style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700)),
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.ink,
                  indicatorColor: AppColors.amber,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Expenses'),
                    Tab(text: 'Balances'),
                    Tab(text: 'Members'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(tab: tab, yourBalance: yourBalance),
                _ExpensesTab(tab: tab),
                _BalancesTab(tab: tab, plan: plan, allSettled: allSettled, onMarkSettled: _markSettled),
                _MembersTab(tab: tab),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FutureBuilder<TabDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _openAddExpense(snapshot.data!),
            icon: const Icon(Icons.add),
            label: const Text('Add expense'),
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.surface,
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final TabDetail tab;
  final double yourBalance;
  const _OverviewTab({required this.tab, required this.yourBalance});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total spent', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(formatCurrency(tab.totalSpent),
                          style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 17)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your balance', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      BalancePill(value: yourBalance),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Recent expenses', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (tab.expenses.isEmpty)
          const _EmptyState(title: 'No expenses yet', body: 'Add your first one.')
        else
          for (final e in tab.expenses.take(4)) _ExpenseRow(tab: tab, expense: e),
      ],
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  final TabDetail tab;
  const _ExpensesTab({required this.tab});

  @override
  Widget build(BuildContext context) {
    if (tab.expenses.isEmpty) {
      return const _EmptyState(title: 'No expenses yet', body: 'Add your first one to get started.');
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [for (final e in tab.expenses) _ExpenseRow(tab: tab, expense: e, showDate: true)],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final TabDetail tab;
  final Expense expense;
  final bool showDate;
  const _ExpenseRow({required this.tab, required this.expense, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(expense.description),
        subtitle: Text(
          '${tab.memberName(expense.paidBy)} paid \u00b7 ${expense.participants.length} people'
          '${showDate ? ' \u00b7 ${expense.date.toIso8601String().split('T').first}' : ''}',
        ),
        trailing: Text(formatCurrency(expense.amount),
            style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _BalancesTab extends StatelessWidget {
  final TabDetail tab;
  final List<SettlementSuggestionPlan> plan;
  final bool allSettled;
  final void Function(String from, String to, double amount) onMarkSettled;

  const _BalancesTab({
    required this.tab,
    required this.plan,
    required this.allSettled,
    required this.onMarkSettled,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Balances', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        for (final m in tab.members)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(m.displayName),
              trailing: (tab.balances[m.id] ?? 0).abs() < 0.01
                  ? const Text('Settled')
                  : BalancePill(value: tab.balances[m.id] ?? 0),
            ),
          ),
        const SizedBox(height: 20),
        const Text('Suggested settlements', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (allSettled)
          const _EmptyState(title: "You're all settled!", body: 'No outstanding balances in this tab.', celebrate: true)
        else
          for (final p in plan)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('${tab.memberName(p.from)} owes ${tab.memberName(p.to)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formatCurrency(p.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => onMarkSettled(p.from, p.to, p.amount),
                      child: const Text('Mark settled'),
                    ),
                  ],
                ),
              ),
            ),
        if (tab.settlements.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Settlement history', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final s in tab.settlements)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('${tab.memberName(s.paidBy)} paid ${tab.memberName(s.paidTo)}'),
                trailing: Text(formatCurrency(s.amount)),
              ),
            ),
        ],
      ],
    );
  }
}

class _MembersTab extends StatelessWidget {
  final TabDetail tab;
  const _MembersTab({required this.tab});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final m in tab.members)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.amber,
                child: Text(m.displayName.isNotEmpty ? m.displayName[0] : '?',
                    style: const TextStyle(color: Colors.white)),
              ),
              title: Text(m.displayName),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String body;
  final bool celebrate;
  const _EmptyState({required this.title, required this.body, this.celebrate = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          MascotIllustration(settled: celebrate, width: 120),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
