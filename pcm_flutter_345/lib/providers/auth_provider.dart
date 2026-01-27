import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SignalRService _signalRService = SignalRService();

  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      final token = await _apiService.getToken();
      if (token != null) {
        final userData = await _apiService.getCurrentUser();
        _user = User.fromJson(userData);
        _isAuthenticated = true;
        
        // Connect to SignalR
        await _signalRService.connect();
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      await _apiService.clearToken();
    }
    _setLoading(false);
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _apiService.login(email, password);
      
      print('Login response: $response'); // Debug log
      
      // Save token
      await _apiService.setToken(response['token']);
      
      // Set user data
      _user = User.fromJson(response['user']);
      _isAuthenticated = true;
      
      print('User role after login: ${_user?.role}'); // Debug log
      
      // Connect to SignalR
      await _signalRService.connect();
      
      _setLoading(false);
      return true;
    } catch (e) {
      print('Login error: $e'); // Debug log
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    print('AuthProvider.register called with email: $email'); // Debug log
    
    _setLoading(true);
    _clearError();
    
    try {
      print('Calling API service register...'); // Debug log
      await _apiService.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      
      print('API register successful'); // Debug log
      _setLoading(false);
      return true;
    } catch (e) {
      print('API register failed: $e'); // Debug log
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    print('AuthProvider.logout() called'); // Debug log
    _setLoading(true);
    
    try {
      // Disconnect SignalR
      await _signalRService.disconnect();
      
      // Clear token
      await _apiService.clearToken();
      
      // Clear user data
      _user = null;
      _isAuthenticated = false;
      print('AuthProvider: User cleared, isAuthenticated = $_isAuthenticated'); // Debug log
    } catch (e) {
      print('AuthProvider logout error: $e'); // Debug log
      // Even if there's an error, we should clear local data
      _user = null;
      _isAuthenticated = false;
      await _apiService.clearToken();
    }
    
    _setLoading(false);
    print('AuthProvider.logout() completed, isAuthenticated = $_isAuthenticated'); // Debug log
  }

  Future<void> refreshUser() async {
    if (!_isAuthenticated) return;
    
    try {
      final userData = await _apiService.getCurrentUser();
      _user = User.fromJson(userData);
      notifyListeners();
    } catch (e) {
      // If refresh fails, user might need to login again
      await logout();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper getters
  String get displayName => _user?.fullName ?? 'Người dùng';
  String get memberTier => _user?.member?.tierDisplayName ?? 'Đồng';
  double get walletBalance => _user?.member?.walletBalance ?? 0.0;
  bool get isVipMember => _user?.member?.tier == 'Gold' || _user?.member?.tier == 'Diamond';
}