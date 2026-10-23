import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class CreateTabScreen extends StatefulWidget {
  final ApiClient api;
  const CreateTabScreen({super.key, required this.api});

  @override
  State<CreateTabScreen> createState() => _CreateTabScreenState();
}

class _CreateTabScreenState extends State<CreateTabScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _memberControllers = [TextEditingController(), TextEditingController()];
  bool _loading = false;
  String? _error;

  void _addMemberField() {
    setState(() => _memberControllers.add(TextEditingController()));
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });

    final name = _nameController.text.trim();
    final members = _memberControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    if (name.isEmpty) {
      setState(() => _error = 'Enter a tab name');
      return;
    }
    if (members.isEmpty) {
      setState(() => _error = 'Add at least one member');
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.api.createTab(name, _descriptionController.text.trim(), members);
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
      appBar: AppBar(title: const Text('New tab')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tab name')),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 20),
            const Text('Members', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (var i = 0; i < _memberControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _memberControllers[i],
                  decoration: InputDecoration(labelText: 'Person ${i + 1}'),
                ),
              ),
            TextButton(onPressed: _addMemberField, child: const Text('+ Add another person')),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.coral)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Creating...' : 'Create tab'),
            ),
          ],
        ),
      ),
    );
  }
}
