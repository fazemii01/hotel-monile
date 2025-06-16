import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_functions.dart'
    as api; // Assuming your api_functions.dart is in utils

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;
  bool _isLoggedIn = false;

  String? get token => _token;
  String? get userId => _userId;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getString('userId');
    if (_token != null && _token!.isNotEmpty) {
      _isLoggedIn = true;
      // You might want to validate the token here with an API call
    } else {
      _isLoggedIn = false;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await api.loginUser(email, password);
      if (response != null && response.containsKey('token')) {
        _token = response['token'];
        // Assuming userId is also returned and stored by loginUser in SharedPreferences
        // Or extract it from response if available directly
        if (response.containsKey('userId')) {
          _userId = response['userId']?.toString();
        } else {
          // Attempt to get from prefs if loginUser stored it
          final prefs = await SharedPreferences.getInstance();
          _userId = prefs.getString('userId');
        }

        if (_token != null && _token!.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          if (_userId != null) {
            await prefs.setString('userId', _userId!);
          }
          _isLoggedIn = true;
          notifyListeners();
          return true;
        }
      }
      _isLoggedIn = false;
      notifyListeners();
      return false;
    } catch (e) {
      print("Login error in AuthProvider: $e");
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    // Potentially call a backend logout endpoint if one exists
    notifyListeners();
  }

  Future<bool> register(Map<String, dynamic> registrationData) async {
    try {
      final response = await api.registerUser(registrationData);
      if (response != null) {
        // Optionally auto-login the user or prompt them to login
        print("Registration successful: $response");
        return true;
      }
      return false;
    } catch (e) {
      print("Registration error in AuthProvider: $e");
      return false;
    }
  }
}
