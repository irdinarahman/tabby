import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/app_refresh.dart';
import '../services/current_user.dart';
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
  final List<TextEditingController> _memberControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final c in _memberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMemberField() {
    setState(() {
      _memberControllers.add(TextEditingController());
    });
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });

    final name = _nameController.text.trim();
    final members = _memberControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    if (name.isEmpty) {
      setState(() {
        _error = 'Give the tab a name, like \u201cLangkawi weekend\u201d.';
      });
      return;
    }
    if (members.isEmpty) {
      setState(() {
        _error = 'Add at least one other person.';
      });
      return;
    }
    final lower = [
      (CurrentUser.instance.name ?? '').toLowerCase(),
      ...members.map((m) => m.toLowerCase()),
    ];
    if (lower.toSet().length != lower.length) {
      setState(() {
        _error = 'Each person needs a different name.';
      });
      return;
    }

    setState(() {
      _loading = true;
    });
    try {
      final description = _descriptionController.text.trim();
      await widget.api.createTab(name, description.isEmpty ? null : description, members);
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
    return Scaffold(
      appBar: AppBar(title: const Text('New tab', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Tab name', hintText: 'Langkawi weekend'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 22),
            const Text('Who\u2019s in?', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            const Text('You\u2019re added automatically.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 10),
            for (var i = 0; i < _memberControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _memberControllers[i],
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: 'Person ${i + 1}'),
                ),
              ),
            TextButton.icon(
              onPressed: _addMemberField,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add another person'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.coral, fontSize: 13)),
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
