import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'activity_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'tabs_screen.dart';

/// The logged-in app: four sections behind a bottom navigation bar.
/// Opening a tab pushes a full screen on top, so the bar hides there.
class AppShell extends StatefulWidget {
  final ApiClient api;
  const AppShell({super.key, required this.api});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            api: widget.api,
            onSeeAllActivity: () {
              setState(() {
                _index = 2;
              });
            },
          ),
          TabsScreen(api: widget.api),
          ActivityScreen(api: widget.api),
          ProfileScreen(api: widget.api),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() {
            _index = i;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Tabs',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
