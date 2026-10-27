import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/app_refresh.dart';
import '../services/expense_emoji.dart';
import '../services/settlement_optimizer.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_pill.dart';
import '../widgets/cat_mark.dart';
import '../widgets/empty_state.dart';
import '../widgets/stripes.dart';
import 'add_expense_screen.dart';

const _sectionStyle = TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 15);
const _mutedStyle = TextStyle(fontSize: 13, color: AppColors.muted);

const _subLabels = <String, String>{
  'overview': 'Overview',
  'expenses': 'Expenses',
  'balances': 'Balances',
  'settlements': 'Settlements',
};

class TabDetailScreen extends StatefulWidget {
  final ApiClient api;
  final String tabId;
  const TabDetailScreen({super.key, required this.api, required this.tabId});

  @override
  State<TabDetailScreen> createState() => _TabDetailScreenState();
}

class _TabDetailScreenState extends State<TabDetailScreen> {
  TabDetail? _detail;
  String? _error;
  bool _loading = true;
  String _sub = 'overview';
  final _personController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppRefresh.version.addListener(_onBump);
    _load();
  }

  @override
  void dispose() {
    AppRefresh.version.removeListener(_onBump);
    _personController.dispose();
    super.dispose();
  }

  void _onBump() {
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await widget.api.fetchTab(widget.tabId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _load();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAddExpense(TabDetail d) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddExpenseScreen(api: widget.api, tab: d)),
    );
    if (added == true) _snack('Expense added');
  }

  Future<void> _openExpense(TabDetail d, Expense e) async {
    final deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _ExpenseSheet(api: widget.api, tab: d, expense: e),
    );
    if (deleted == true) _snack('Expense deleted');
  }

  Future<void> _addPerson(TabDetail d) async {
    final name = _personController.text.trim();
    if (name.isEmpty) {
      _snack('Enter a name first');
      return;
    }
    final exists = d.members.any((m) => m.displayName.toLowerCase() == name.toLowerCase());
    if (exists) {
      _snack('$name is already in this tab');
      return;
    }
    try {
      await widget.api.addMember(d.id, name);
      _personController.clear();
      AppRefresh.bump();
      _snack('$name added');
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _settle(TabDetail d, SettlementSuggestionPlan p) async {
    try {
      await widget.api.markSettled(tabId: d.id, paidBy: p.from, paidTo: p.to, amount: p.amount);
      AppRefresh.bump();
      _snack('Settlement recorded');
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: d == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openAddExpense(d),
              icon: const Icon(Icons.add),
              label: const Text('Add expense'),
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.surface,
            ),
      body: d != null
          ? _content(d)
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : ErrorState(message: _error ?? 'Something went wrong.', onRetry: _retry),
    );
  }

  Widget _content(TabDetail d) {
    final me = d.me;
    final myBalance = me == null ? 0.0 : (d.balances[me.id] ?? 0.0);
    final square = myBalance.abs() < 0.01;
    final balanceLabel = square ? 'Your balance' : (myBalance > 0 ? 'You\u2019re owed' : 'You owe');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.name,
                  style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              const Stripes(),
            ],
          ),
          if (d.description != null && d.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(d.description!, style: _mutedStyle),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total spent',
                  child: Text(
                    formatCurrency(d.totalSpent),
                    style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: balanceLabel,
                  child: square
                      ? const Text(
                          'Settled',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.muted),
                        )
                      : BalancePill(value: myBalance),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _subTabs(),
          const SizedBox(height: 18),
          ..._panel(d),
        ],
      ),
    );
  }

  Widget _subTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in _subLabels.entries)
              _SubTab(
                label: entry.value,
                selected: _sub == entry.key,
                onTap: () {
                  setState(() {
                    _sub = entry.key;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _panel(TabDetail d) {
    switch (_sub) {
      case 'expenses':
        return _expensesPanel(d);
      case 'balances':
        return _balancesPanel(d);
      case 'settlements':
        return _settlementsPanel(d);
      default:
        return _overviewPanel(d);
    }
  }

  // ---------- overview ----------

  List<Widget> _overviewPanel(TabDetail d) {
    final recent = d.expenses.take(4).toList();
    final meId = d.me?.id;
    return [
      _StatusCard(detail: d),
      const SizedBox(height: 24),
      const Text('Members', style: _sectionStyle),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final m in d.members) _MemberChip(member: m, isMe: m.id == meId),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _personController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addPerson(d),
              decoration: const InputDecoration(hintText: 'Add someone by name'),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: () => _addPerson(d), child: const Text('Add')),
        ],
      ),
      const SizedBox(height: 6),
      const Text('No account needed. Friends can join with just a name.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      const SizedBox(height: 26),
      Row(
        children: [
          const Expanded(child: Text('Recent expenses', style: _sectionStyle)),
          if (d.expenses.length > 4)
            TextButton(
              onPressed: () {
                setState(() {
                  _sub = 'expenses';
                });
              },
              child: const Text('See all'),
            ),
        ],
      ),
      const SizedBox(height: 10),
      if (recent.isEmpty)
        const EmptyState(title: 'No expenses yet', body: 'Add your first one.')
      else
        ..._expenseRows(d, recent, false),
    ];
  }

  List<Widget> _expenseRows(TabDetail d, List<Expense> list, bool showDate) {
    final meId = d.me?.id;
    return [
      for (final e in list)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ExpenseRow(
            expense: e,
            payer: e.paidBy == meId ? 'You' : d.memberName(e.paidBy),
            showDate: showDate,
            onTap: () => _openExpense(d, e),
          ),
        ),
    ];
  }

  // ---------- expenses ----------

  List<Widget> _expensesPanel(TabDetail d) {
    if (d.expenses.isEmpty) {
      return const [EmptyState(title: 'No expenses yet', body: 'Add your first one.')];
    }
    return _expenseRows(d, d.expenses, true);
  }

  // ---------- balances ----------

  List<Widget> _balancesPanel(TabDetail d) {
    final plan = SettlementOptimizer().plan(d.balances);
    final meId = d.me?.id;
    String who(String id) => id == meId ? 'You' : d.memberName(id);

    return [
      Text.rich(
        TextSpan(
          style: _mutedStyle,
          children: const [
            TextSpan(text: 'A '),
            TextSpan(text: '+', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
            TextSpan(text: ' balance means that person is owed money. A '),
            TextSpan(text: '\u2212', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700)),
            TextSpan(text: ' balance means they owe money.'),
          ],
        ),
      ),
      const SizedBox(height: 14),
      for (final m in d.members)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _BalanceRow(
            name: m.id == meId ? '${m.displayName} (you)' : m.displayName,
            value: d.balances[m.id] ?? 0.0,
          ),
        ),
      const SizedBox(height: 18),
      const Text('Suggested payments', style: _sectionStyle),
      if (plan.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${plural(plan.length, 'payment settles', 'payments settle')} everyone up.',
            style: _mutedStyle,
          ),
        ),
      const SizedBox(height: 12),
      if (plan.isEmpty)
        const EmptyState(title: 'You\u2019re all settled!', body: 'No outstanding balances in this tab.', settled: true)
      else
        for (final p in plan)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${who(p.from)} \u2192 ${who(p.to)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatCurrency(p.amount),
                            style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => _settle(d, p),
                      child: const Text('Mark settled'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    ];
  }

  // ---------- settlements ----------

  List<Widget> _settlementsPanel(TabDetail d) {
    if (d.settlements.isEmpty) {
      return const [EmptyState(title: 'No settlements yet', body: 'When someone pays up, it shows here.')];
    }
    final meId = d.me?.id;
    String who(String id, {bool object = false}) {
      if (id == meId) return object ? 'you' : 'You';
      return d.memberName(id);
    }

    return [
      for (final s in d.settlements)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${who(s.paidBy)} paid ${who(s.paidTo, object: true)} ${formatCurrency(s.amount)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(formatDateLong(s.settledAt.toLocal()), style: _mutedStyle),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tealTint),
                    child: const Icon(Icons.check_rounded, size: 17, color: AppColors.teal),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }
}

// ---------- small pieces ----------

class _StatCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _StatCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted)),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
}

class _SubTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SubTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.only(top: 12, bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: selected ? AppColors.amber : Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.ink : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final Member member;
  final bool isMe;
  const _MemberChip({required this.member, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final name = member.displayName;
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.amber,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 8),
          Text(isMe ? '$name (you)' : name, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final TabDetail detail;
  const _StatusCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final meId = d.me?.id;
    final allSettled = d.balances.values.every((v) => v.abs() < 0.01);

    Widget icon = const CatMark(size: 40);
    var lines = <String>[];

    if (d.expenses.isEmpty) {
      lines = ['Nothing to split yet', 'Add the first expense to get started.'];
    } else if (allSettled) {
      icon = const MascotIllustration(settled: true, width: 64);
      lines = ['You\u2019re all settled!', 'No outstanding balances in this tab.'];
    } else {
      final plan = SettlementOptimizer().plan(d.balances);
      final mine = plan.where((p) => p.from == meId || p.to == meId).toList();
      if (mine.isEmpty) {
        lines = ['You\u2019re square.', 'Others still have payments to sort out.'];
      } else {
        lines = [
          for (final p in mine.take(2))
            p.to == meId
                ? '${d.memberName(p.from)} owes you ${formatCurrency(p.amount)}.'
                : 'You owe ${d.memberName(p.to)} ${formatCurrency(p.amount)}.',
        ];
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lines.first,
                    style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  for (final extra in lines.skip(1))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(extra, style: _mutedStyle),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final Expense expense;
  final String payer;
  final bool showDate;
  final VoidCallback onTap;

  const _ExpenseRow({
    required this.expense,
    required this.payer,
    required this.showDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final people = plural(expense.participants.length, 'person', 'people');
    final date = showDate ? ' \u00b7 ${formatDate(expense.date)}' : '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.amberTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(emojiFor(expense.description), style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 3),
                    Text('$payer paid \u00b7 $people$date', style: _mutedStyle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatCurrency(expense.amount),
                style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String name;
  final double value;
  const _BalanceRow({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    final square = value.abs() < 0.01;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            if (square)
              const Text(
                'Settled',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BalancePill(value: value),
                  const SizedBox(height: 2),
                  Text(value > 0 ? 'is owed' : 'owes', style: _mutedStyle),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseSheet extends StatefulWidget {
  final ApiClient api;
  final TabDetail tab;
  final Expense expense;
  const _ExpenseSheet({required this.api, required this.tab, required this.expense});

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: const Text('Balances will update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('Delete expense'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.deleteExpense(widget.tab.id, widget.expense.id);
      AppRefresh.bump();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final e = widget.expense;
    final meId = tab.me?.id;
    String who(String id, {bool object = false}) {
      if (id == meId) return object ? 'you' : 'You';
      return tab.memberName(id);
    }

    final method = e.splitMethod == 'equal' ? 'Split equally' : 'Custom split';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emojiFor(e.description), style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.description,
                    style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 17),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency(e.amount),
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 30),
            ),
            const SizedBox(height: 4),
            Text('${who(e.paidBy)} paid on ${formatDateLong(e.date)}', style: _mutedStyle),
            const SizedBox(height: 2),
            Text(
              '$method between ${plural(e.participants.length, 'person', 'people')}',
              style: _mutedStyle,
            ),
            const SizedBox(height: 14),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
              child: Column(
                children: [
                  for (final p in e.participants)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.line)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(who(p.tabMemberId), style: const TextStyle(fontSize: 14))),
                          Text(
                            formatCurrency(p.shareAmount),
                            style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (e.notes != null && e.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(e.notes!, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.coral, fontSize: 13)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : _delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  side: const BorderSide(color: AppColors.coral),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                child: Text(_busy ? 'Deleting...' : 'Delete expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
