import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'current_user.dart';

/// Thrown for any failed request. [message] is written for the person using
/// the app, so screens can show it as-is.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  // Override at run time with --dart-define=TABBY_API_BASE_URL=...
  static const String baseUrl = String.fromEnvironment(
    'TABBY_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
  static const Duration _timeout = Duration(seconds: 12);

  String? _token;

  // ---------- session storage ----------

  Future<void> _loadToken() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await _saveUser(user);
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    CurrentUser.instance.id = user['id'] as String;
    CurrentUser.instance.name = user['name'] as String;
    CurrentUser.instance.email = user['email'] as String?;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user', jsonEncode(user));
  }

  Future<void> clearSession() async {
    _token = null;
    CurrentUser.instance.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  /// Restores a saved login without touching the network, so the app opens
  /// even when offline. Returns false if nobody is logged in.
  Future<bool> restoreSession() async {
    await _loadToken();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('auth_user');
    if (_token == null || raw == null) return false;
    try {
      final user = jsonDecode(raw) as Map<String, dynamic>;
      CurrentUser.instance.id = user['id'] as String;
      CurrentUser.instance.name = user['name'] as String;
      CurrentUser.instance.email = user['email'] as String?;
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  // ---------- request plumbing ----------

  dynamic _decode(http.Response res) {
    final dynamic body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    if (res.statusCode == 401) {
      unawaited(clearSession());
      throw ApiException('Your session has expired. Please log out and log in again.');
    }

    var message = 'Something went wrong (${res.statusCode}).';
    if (body is Map) {
      if (body['message'] is String) message = body['message'] as String;
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) message = first.first.toString();
      }
    }
    throw ApiException(message);
  }

  Future<dynamic> _request(String method, String path, {Object? body}) async {
    await _loadToken();
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    final encoded = body == null ? null : jsonEncode(body);

    try {
      final http.Response res;
      switch (method) {
        case 'GET':
          res = await http.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          res = await http.post(uri, headers: headers, body: encoded).timeout(_timeout);
          break;
        case 'PATCH':
          res = await http.patch(uri, headers: headers, body: encoded).timeout(_timeout);
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          throw ArgumentError('Unsupported method $method');
      }
      return _decode(res);
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Check your connection and try again.');
    } on http.ClientException {
      throw ApiException('Can\u2019t reach the server. Check your connection and the API address.');
    } on FormatException {
      throw ApiException('The server sent an unexpected response.');
    }
  }

  // ---------- auth ----------

  Future<void> login(String email, String password) async {
    final data = await _request('POST', '/login', body: {'email': email, 'password': password});
    await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>);
  }

  Future<void> register(String name, String email, String password) async {
    final data = await _request('POST', '/register', body: {'name': name, 'email': email, 'password': password});
    await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/logout');
    } on ApiException {
      // Logging out locally is enough if the server can't be reached.
    }
    await clearSession();
  }

  Future<void> updateProfile({required String name, required String email}) async {
    final data = await _request('PATCH', '/me', body: {'name': name, 'email': email});
    await _saveUser(data as Map<String, dynamic>);
  }

  // ---------- tabs ----------

  Future<List<TabSummary>> fetchTabs() async {
    final data = await _request('GET', '/tabs') as List<dynamic>;
    return data.map((t) => TabSummary.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<TabDetail> fetchTab(String tabId) async {
    final data = await _request('GET', '/tabs/$tabId');
    return TabDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<void> createTab(String name, String? description, List<String> memberNames) async {
    await _request('POST', '/tabs', body: {
      'name': name,
      'description': description,
      'member_names': memberNames,
    });
  }

  Future<void> addMember(String tabId, String displayName) async {
    await _request('POST', '/tabs/$tabId/members', body: {'display_name': displayName});
  }

  // ---------- expenses ----------

  Future<void> addExpense({
    required String tabId,
    required String description,
    required double amount,
    required String paidBy,
    required String splitMethod,
    required DateTime date,
    required List<ExpenseParticipant> participants,
    String? notes,
  }) async {
    await _request('POST', '/tabs/$tabId/expenses', body: {
      'description': description,
      'amount': amount,
      'paid_by': paidBy,
      'split_method': splitMethod,
      'expense_date': date.toIso8601String().split('T').first,
      'notes': notes,
      'participants': participants.map((p) => p.toJson()).toList(),
    });
  }

  Future<void> deleteExpense(String tabId, String expenseId) async {
    await _request('DELETE', '/tabs/$tabId/expenses/$expenseId');
  }

  // ---------- settlements ----------

  Future<List<SettlementSuggestion>> fetchSettlementSuggestions(String tabId) async {
    final data = await _request('GET', '/tabs/$tabId/settlements/suggestions') as List<dynamic>;
    return data.map((s) => SettlementSuggestion.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<void> markSettled({
    required String tabId,
    required String paidBy,
    required String paidTo,
    required double amount,
  }) async {
    await _request('POST', '/tabs/$tabId/settlements', body: {
      'paid_by': paidBy,
      'paid_to': paidTo,
      'amount': amount,
    });
  }
}
