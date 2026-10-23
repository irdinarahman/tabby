import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TabbyApp());
}

class TabbyApp extends StatelessWidget {
  const TabbyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tabby',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _StartupGate(),
    );
  }
}

/// Restores a saved session (if any) before deciding whether to show the
/// login screen or drop straight into the home dashboard.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  final _api = ApiClient();
  late Future<bool> _restoring;

  @override
  void initState() {
    super.initState();
    _restoring = _api.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restoring,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final loggedIn = snapshot.data ?? false;
        return loggedIn ? HomeScreen(api: _api) : AuthScreen(api: _api);
      },
    );
  }
}
