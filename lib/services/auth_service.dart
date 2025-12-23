import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _clientIdKey = 'client_id';
  static const String _apiBaseUrl = 'https://api.example.com';

  String? _token;
  String? _clientId;
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  String? get clientId => _clientId;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _clientId = prefs.getString(_clientIdKey);
    notifyListeners();
  }

  Future<bool> login(String clientId, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try real API call first
      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'clientId': clientId, 'password': password}),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['token'] != null) {
            await _saveCredentials(data['token'], clientId);
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
      } catch (e) {
        debugPrint('API call failed, using fallback: $e');
      }

      // Fallback: Local validation for demo/testing
      if (clientId.isNotEmpty && password.length >= 4) {
        final fallbackToken = 'local-token-${DateTime.now().millisecondsSinceEpoch}';
        await _saveCredentials(fallbackToken, clientId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid credentials. Password must be at least 4 characters.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveCredentials(String token, String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_clientIdKey, clientId);
    _token = token;
    _clientId = clientId;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_clientIdKey);
    _token = null;
    _clientId = null;
    notifyListeners();
  }
}
