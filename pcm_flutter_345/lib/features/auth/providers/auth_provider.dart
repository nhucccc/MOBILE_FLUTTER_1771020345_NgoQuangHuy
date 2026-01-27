import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/signalr_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SignalRService _signalRService;

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  AuthProvider(this._authService, this._signalRService) {
    _initializeAuth();
  }

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _user?.member?.tier == 'Admin' || _user?.id == 'admin';

  Future<void> _initializeAuth() async {
    _setLoading(true);
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _user = await _authService.getCachedUser();
        _isAuthenticated = true;
        
        // Connect to SignalR
        final token = await _authService._storageService.getToken();
        await _signalRService.connect(token);
        
        // Refresh user data
        await refreshUserData();
      }
    } catch (e) {
      _setError('Lỗi khởi tạo: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final loginResponse = await _authService.login(email, password);
      _user = loginResponse.user;
      _isAuthenticated = true;
      
      // Connect to SignalR
      await _signalRService.connect(loginResponse.token);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Đăng nhập thất bại: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName, {String? phoneNumber}) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.register(email, password, fullName, phoneNumber: phoneNumber);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Đăng ký thất bại: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _signalRService.disconnect();
      await _authService.logout();
      _user = null;
      _isAuthenticated = false;
      _clearError();
    } catch (e) {
      _setError('Lỗi đăng xuất: ${e.toString()}');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refreshUserData() async {
    try {
      await _authService.refreshUserData();
      _user = await _authService.getCachedUser();
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('401')) {
        await logout();
      }
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

  @override
  void dispose() {
    _signalRService.disconnect();
    super.dispose();
  }
}