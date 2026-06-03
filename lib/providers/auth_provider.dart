import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  bool _isAuthenticated = false;
  int _userId = 0;
  String _role = 'customer';
  String _username = '';
  String _namaLengkap = '';

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  int get userId => _userId;
  String get role => _role;
  String get username => _username;
  String get namaLengkap => _namaLengkap;

  AuthProvider() {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('user_id') ?? 0;
      
      if (_userId != 0) {
        _isAuthenticated = true;
        _role = prefs.getString('role') ?? 'customer';
        _username = prefs.getString('username') ?? '';
        _namaLengkap = prefs.getString('nama_lengkap') ?? '';
      } else {
        _isAuthenticated = false;
        _role = 'customer';
      }
    } catch (e) {
      print('Error checking login status: $e');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.login(username, password);
    
    if (result['success']) {
      await _apiService.saveUserSession(result['user']);
      await checkLoginStatus(); // This will notify listeners
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return result;
  }
  
  Future<Map<String, dynamic>> googleLogin(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.googleLogin(data);
    
    if (result['success']) {
      await _apiService.saveUserSession(result['user']);
      await checkLoginStatus(); // This will notify listeners
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return result;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    await _apiService.logout();
    await checkLoginStatus();
  }
}
