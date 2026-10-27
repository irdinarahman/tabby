import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/app_refresh.dart';
import 'empty_state.dart';

/// Loads data once, shows it, and quietly reloads whenever [AppRefresh] fires
/// or the person pulls down. Existing content stays on screen while a reload
/// runs, so nothing flickers after an edit.
class AsyncBody<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  const AsyncBody({super.key, required this.load, required this.builder});

  @override
  State<AsyncBody<T>> createState() => _AsyncBodyState<T>();
}

class _AsyncBodyState<T> extends State<AsyncBody<T>> {
  T? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppRefresh.version.addListener(_onBump);
    _run();
  }

  @override
  void dispose() {
    AppRefresh.version.removeListener(_onBump);
    super.dispose();
  }

  void _onBump() {
    _run();
  }

  Future<void> _run() async {
    try {
      final data = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = data;
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
    await _run();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data != null) {
      return RefreshIndicator(onRefresh: _run, child: widget.builder(context, data));
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ErrorState(message: _error ?? 'Something went wrong.', onRetry: _retry);
  }
}
