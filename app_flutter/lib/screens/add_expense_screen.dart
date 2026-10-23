import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_client.dart';
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
  late String _paidBy;
  String _splitMethod = 'equal';
  late Set<String> _included;
  final Map<String, TextEditingController> _customControllers = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _paidBy = widget.tab.members.first.id;
    _included = widget.tab.members.map((m) => m.id).toSet();
    for (final m in widget.tab.members) {
      _customControllers[m.id] = TextEditingController();
    }
  }

  double get _customTotal {
    return _included.fold(0.0, (sum, id) {
      final v = double.tryParse(_customControllers[id]?.text ?? '') ?? 0.0;
      return sum + v;
    });
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (description.isEmpty) {
      setState(() => _error = 'Enter a description');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (_included.isEmpty) {
      setState(() => _error = 'Select at least one person');
      return;
    }

    List<ExpenseParticipant> participants;
    if (_splitMethod == 'equal') {
      final share = double.parse((amount / _included.length).toStringAsFixed(2));
      participants = _included.map((id) => ExpenseParticipant(tabMemberId: id, shareAmount: share)).toList();
    } else {
      final sum = double.parse(_customTotal.toStringAsFixed(2));
      if ((sum - amount).abs() > 0.01) {
        setState(() => _error =
            'Custom amounts must add up to ${formatCurrency(amount)} (currently ${formatCurrency(sum)})');
        return;
      }
      participants = _included
          .map((id) => ExpenseParticipant(
                tabMemberId: id,
                shareAmount: double.tryParse(_customControllers[id]?.text ?? '') ?? 0.0,
              ))
          .toList();
    }

    setState(() => _loading = true);
    try {
      await widget.api.addExpense(
        tabId: widget.tab.id,
        description: description,
        amount: amount,
        paidBy: _paidBy,
        splitMethod: _splitMethod,
        date: DateTime.now(),
        participants: participants,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New expense')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (RM)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _paidBy,
              decoration: const InputDecoration(labelText: 'Paid by'),
              items: widget.tab.members
                  .map((m) => DropdownMenuItem(value: m.id, child: Text(m.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => _paidBy = v!),
            ),
            const SizedBox(height: 16),
            const Text('Split method', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'equal', label: Text('Equal')),
                ButtonSegment(value: 'custom', label: Text('Custom')),
              ],
              selected: {_splitMethod},
              onSelectionChanged: (s) => setState(() => _splitMethod = s.first),
            ),
            const SizedBox(height: 16),
            const Text('Split between', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
            for (final m in widget.tab.members)
              Row(
                children: [
                  Checkbox(
                    value: _included.contains(m.id),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _included.add(m.id);
                      } else {
                        _included.remove(m.id);
                      }
                    }),
                  ),
                  Expanded(child: Text(m.displayName)),
                  if (_splitMethod == 'custom' && _included.contains(m.id))
                    SizedBox(
                      width: 90,
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
            if (_splitMethod == 'custom')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Entered: ${formatCurrency(_customTotal)} of ${_amountController.text.isEmpty ? 'RM 0.00' : formatCurrency(double.tryParse(_amountController.text) ?? 0)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.ink),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.coral)),
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
