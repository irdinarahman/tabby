import 'package:flutter/foundation.dart';

/// A tiny "something changed" signal. Any screen that changes data (new tab,
/// new expense, settlement, delete...) calls [bump]; screens that show data
/// listen to [version] and quietly reload. This keeps Home, Tabs, Activity
/// and the open tab in sync without a heavier state-management setup.
class AppRefresh {
  AppRefresh._();
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static void bump() {
    version.value++;
  }
}
