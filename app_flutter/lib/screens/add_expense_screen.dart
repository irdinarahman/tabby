import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/app_refresh.dart';
import '../theme/app_theme.dart';

class AddExpenseScreen extends StatefulWidget {
  final ApiClient api;
  final TabDetail tab;
  const AddExpenseScreen({super.key, required this.api, required this.tab});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<String, TextEditingController> _customControllers = {};
  late String _paidBy;
  late Set<String> _included;
  String _splitMethod = 'equal';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _paidBy = widget.tab.me?.id ?? widget.tab.members.first.id;
    _included = widget.tab.members.map((m) => m.id).toSet();
    for (final m in widget.tab.members) {
      _customControllers[m.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Parses "12", "12.5", "1,250.00". Returns null if it isn't a valid amount.
  double? _parse(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  int _cents(double v) => (v * 100).round();

  double get _customTotal {
    var sum = 0.0;
    for (final id in _included) {
      sum += _parse(_customControllers[id]?.text ?? '') ?? 0.0;
    }
    return sum;
  }

  String _hint() {
    final amount = _parse(_amountController.text);
    if (_included.isEmpty) return 'Pick at least one person.';
    if (_splitMethod == 'equal') {
      if (amount == null || amount <= 0) return '';
      final each = amount / _included.length;
      final uneven = _cents(amount) % _included.length != 0;
      return '${uneven ? 'About ' : ''}${formatCurrency(each)} each';
    }
    final entered = _customTotal;
    if (amount == null || amount <= 0) return 'Entered ${formatCurrency(entered)}';
    final diff = _cents(amount) - _cents(entered);
    if (diff == 0) return 'Entered ${formatCurrency(entered)}. Adds up.';
    if (diff > 0) {
      return 'Entered ${formatCurrency(entered)} of ${formatCurrency(amount)}. ${formatCurrency(diff / 100)} left to assign.';
    }
    return 'Entered ${formatCurrency(entered)} of ${formatCurrency(amount)}. ${formatCurrency(-diff / 100)} over.';
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });

    final description = _descriptionController.text.trim();
    final amount = _parse(_amountController.text);

    if (description.isEmpty) {
      setState(() {
        _error = 'Add a short description, like \u201cDinner\u201d.';
      });
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() {
        _error = 'Enter an amount greater than zero.';
      });
      return;
    }
    if (_included.isEmpty) {
      setState(() {
        _error = 'Pick at least one person to split with.';
      });
      return;
    }

    late final List<ExpenseParticipant> participants;
    if (_splitMethod == 'equal') {
      final share = double.parse((amount / _included.length).toStringAsFixed(2));
      participants = _included.map((id) => ExpenseParticipant(tabMemberId: id, shareAmount: share)).toList();
    } else {
      final entered = _customTotal;
      if (_cents(entered) != _cents(amount)) {
        setState(() {
          _error =
              'Custom amounts must add up to ${formatCurrency(amount)}. They add up to ${formatCurrency(entered)} right now.';
        });
        return;
      }
      participants = _included
          .map((id) => ExpenseParticipant(
                tabMemberId: id,
                shareAmount: _parse(_customControllers[id]?.text ?? '') ?? 0.0,
              ))
          .toList();
    }

    setState(() {
      _loading = true;
    });
    try {
      final notes = _notesController.text.trim();
      await widget.api.addExpense(
        tabId: widget.tab.id,
        description: description,
        amount: amount,
        paidBy: _paidBy,
        splitMethod: _splitMethod,
        date: DateTime.now(),
        participants: participants,
        notes: notes.isEmpty ? null : notes,
      );
      AppRefresh.bump();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meId = widget.tab.me?.id;
    final hint = _hint();

    return Scaffold(
      appBar: AppBar(title: const Text('New expense', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'What was it for?', hintText: 'Dinner at Sushi Zen'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (RM)', hintText: '0.00'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _paidBy,
              decoration: const InputDecoration(labelText: 'Paid by'),
              items: [
                for (final m in widget.tab.members)
                  DropdownMenuItem(
                    value: m.id,
                    child: Text(m.id == meId ? '${m.displayName} (you)' : m.displayName),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _paidBy = v;
                });
              },
            ),
            const SizedBox(height: 18),
            const Text('Split', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'equal', label: Text('Equal')),
                ButtonSegment(value: 'custom', label: Text('Custom')),
              ],
              selected: {_splitMethod},
              onSelectionChanged: (s) {
                setState(() {
                  _splitMethod = s.first;
                });
              },
            ),
            const SizedBox(height: 18),
            const Text('Split between', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            for (final m in widget.tab.members)
              Row(
                children: [
                  Checkbox(
                    value: _included.contains(m.id),
                    activeColor: AppColors.rust,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _included.add(m.id);
                        } else {
                          _included.remove(m.id);
                        }
                      });
                    },
                  ),
                  Expanded(child: Text(m.id == meId ? '${m.displayName} (you)' : m.displayName)),
                  if (_splitMethod == 'custom' && _included.contains(m.id))
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _customControllers[m.id],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(hintText: '0.00'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                ],
              ),
            if (hint.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: AppColors.coral, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Saving...' : 'Save expense'),
            ),
          ],
        ),
      ),
    );
  }
}
