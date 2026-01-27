import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _emailKey = 'biometric_email';
  static const String _passwordKey = 'biometric_password';

  // Kiểm tra thiết bị có hỗ trợ sinh trắc học không
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  // Lấy danh sách các loại sinh trắc học có sẵn
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Kiểm tra xem sinh trắc học đã được bật chưa
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      print('Error checking biometric enabled status: $e');
      return false;
    }
  }

  // Bật sinh trắc học
  Future<bool> enableBiometric(String email, String password) async {
    try {
      // Kiểm tra xem thiết bị có hỗ trợ không
      if (!await isBiometricAvailable()) {
        throw 'Thiết bị không hỗ trợ xác thực sinh trắc học';
      }

      // Xác thực sinh trắc học
      final isAuthenticated = await _authenticateWithBiometric();
      
      if (isAuthenticated) {
        // Lưu thông tin đăng nhập
        await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
        await _secureStorage.write(key: _emailKey, value: email);
        await _secureStorage.write(key: _passwordKey, value: password);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error enabling biometric: $e');
      return false;
    }
  }

  // Tắt sinh trắc học
  Future<void> disableBiometric() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _emailKey);
      await _secureStorage.delete(key: _passwordKey);
    } catch (e) {
      print('Error disabling biometric: $e');
    }
  }

  // Xác thực và lấy thông tin đăng nhập
  Future<Map<String, String>?> authenticateAndGetCredentials() async {
    try {
      if (!await isBiometricEnabled()) {
        return null;
      }

      final isAuthenticated = await _authenticateWithBiometric();
      
      if (isAuthenticated) {
        final email = await _secureStorage.read(key: _emailKey);
        final password = await _secureStorage.read(key: _passwordKey);
        
        if (email != null && password != null) {
          return {
            'email': email,
            'password': password,
          };
        }
      }
      
      return null;
    } catch (e) {
      print('Error authenticating with biometric: $e');
      return null;
    }
  }

  // Xác thực sinh trắc học
  Future<bool> _authenticateWithBiometric() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Xác thực để đăng nhập',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return isAuthenticated;
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected biometric error: $e');
      return false;
    }
  }
}