import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'current_user.dart';

/// Thin wrapper around the Laravel API. Every method throws [ApiException]
/// on a non-2xx response so screens can show a real error message instead
/// of a generic failure.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  // Point this at your running Laravel instance. 10.0.2.2 is the Android
  // emulator's alias for the host machine's localhost; use localhost on iOS
  // simulator, or your machine's LAN IP on a physical device.
  static const String baseUrl = String.fromEnvironment(
    'TABBY_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  String? _token;

  Future<void> _loadToken() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<Map<String, String>> _headers() async {
    await _loadToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  dynamic _decodeOrThrow(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    final message = body is Map && body['message'] != null
        ? body['message'] as String
        : 'Something went wrong (${res.statusCode})';
    throw ApiException(message);
  }

  Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decodeOrThrow(res);
    await _saveToken(data['token'] as String);
    CurrentUser.instance.id = data['user']['id'] as String;
    CurrentUser.instance.name = data['user']['name'] as String;
  }

  Future<void> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = _decodeOrThrow(res);
    await _saveToken(data['token'] as String);
    CurrentUser.instance.id = data['user']['id'] as String;
    CurrentUser.instance.name = data['user']['name'] as String;
  }

  /// Call once at app start (if a token is already stored) to repopulate
  /// [CurrentUser] without forcing the person to log in again.
  Future<bool> restoreSession() async {
    await _loadToken();
    if (_token == null) return false;
    try {
      final res = await http.get(Uri.parse('$baseUrl/me'), headers: await _headers());
      final data = _decodeOrThrow(res);
      CurrentUser.instance.id = data['id'] as String;
      CurrentUser.instance.name = data['name'] as String;
      return true;
    } on ApiException {
      await clearToken();
      return false;
    }
  }

  Future<void> logout() async {
    await http.post(Uri.parse('$baseUrl/logout'), headers: await _headers());
    await clearToken();
  }

  Future<List<TabSummary>> fetchTabs() async {
    final res = await http.get(Uri.parse('$baseUrl/tabs'), headers: await _headers());
    final data = _decodeOrThrow(res) as List<dynamic>;
    return data.map((t) => TabSummary.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<TabDetail> fetchTab(String tabId) async {
    final res = await http.get(Uri.parse('$baseUrl/tabs/$tabId'), headers: await _headers());
    return TabDetail.fromJson(_decodeOrThrow(res) as Map<String, dynamic>);
  }

  Future<void> createTab(String name, String? description, List<String> memberNames) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tabs'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'description': description,
        'member_names': memberNames,
      }),
    );
    _decodeOrThrow(res);
  }

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
    final res = await http.post(
      Uri.parse('$baseUrl/tabs/$tabId/expenses'),
      headers: await _headers(),
      body: jsonEncode({
        'description': description,
        'amount': amount,
        'paid_by': paidBy,
        'split_method': splitMethod,
        'expense_date': date.toIso8601String().split('T').first,
        'notes': notes,
        'participants': participants.map((p) => p.toJson()).toList(),
      }),
    );
    _decodeOrThrow(res);
  }

  Future<List<SettlementSuggestion>> fetchSettlementSuggestions(String tabId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/tabs/$tabId/settlements/suggestions'),
      headers: await _headers(),
    );
    final data = _decodeOrThrow(res) as List<dynamic>;
    return data.map((s) => SettlementSuggestion.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<void> markSettled({
    required String tabId,
    required String paidBy,
    required String paidTo,
    required double amount,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tabs/$tabId/settlements'),
      headers: await _headers(),
      body: jsonEncode({'paid_by': paidBy, 'paid_to': paidTo, 'amount': amount}),
    );
    _decodeOrThrow(res);
  }
}
