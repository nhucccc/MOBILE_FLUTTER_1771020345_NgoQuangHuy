import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Tự động chọn URL dựa trên platform
  static String get baseUrl {
    if (kIsWeb) {
      // Web: dùng localhost
      return 'http://localhost:58377/api';
    } else {
      // Mobile (Android/iOS): dùng 10.0.2.2 cho emulator
      return 'http://10.0.2.2:58377/api';
    }
  }
  
  static const String _tokenKey = 'auth_token';
  
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        _logger.d('Request: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        _logger.e('Error: ${error.response?.statusCode} ${error.requestOptions.path}');
        _logger.e('Error message: ${error.message}');
        handler.next(error);
      },
    ));
  }

  // Token management
  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    print('ApiService.register called'); // Debug log
    print('URL: $baseUrl/auth/register'); // Debug log
    
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
      });
      
      print('Register response: ${response.data}'); // Debug log
      return response.data;
    } on DioException catch (e) {
      print('Register DioException: ${e.message}'); // Debug log
      print('Register response data: ${e.response?.data}'); // Debug log
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Wallet endpoints
  Future<double> getWalletBalance() async {
    try {
      final response = await _dio.get('/wallet/balance');
      return response.data.toDouble();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getWalletTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get('/wallet/transactions', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createDepositRequest({
    required double amount,
    required String description,
    String? proofImageUrl,
  }) async {
    try {
      final response = await _dio.post('/wallet/deposit', data: {
        'amount': amount,
        'description': description,
        'proofImageUrl': proofImageUrl,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Booking endpoints
  Future<List<Map<String, dynamic>>> getCourts() async {
    try {
      final response = await _dio.get('/booking/courts');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCalendarBookings({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _dio.get('/booking/calendar', queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      });
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required int courtId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final token = await getToken();
      print('ApiService: Token exists: ${token != null}');
      if (token != null) {
        print('ApiService: Token preview: ${token.substring(0, 20)}...');
      }
      
      final requestData = {
        'CourtId': courtId,  // Viết hoa C để match với backend DTO
        'StartTime': startTime.toIso8601String(),  // Viết hoa S
        'EndTime': endTime.toIso8601String(),  // Viết hoa E
      };
      
      print('ApiService: Creating booking with data: $requestData');
      print('ApiService: Making request to: ${_dio.options.baseUrl}/booking');
      
      final response = await _dio.post('/booking', data: requestData);
      
      print('ApiService: Booking response: ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      print('ApiService: Booking error: ${e.response?.data ?? e.message}');
      print('ApiService: Status code: ${e.response?.statusCode}');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createRecurringBooking({
    required int courtId,
    required DateTime startTime,
    required DateTime endTime,
    required String recurrenceRule,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.post('/booking/recurring', data: {
        'CourtId': courtId,  // Viết hoa C
        'StartTime': startTime.toIso8601String(),  // Viết hoa S
        'EndTime': endTime.toIso8601String(),  // Viết hoa E
        'RecurrenceRule': recurrenceRule,  // Viết hoa R
        'EndDate': endDate.toIso8601String(),  // Viết hoa E
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> cancelBooking(int bookingId) async {
    try {
      await _dio.post('/booking/cancel/$bookingId');
      return true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyBookings({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get('/booking/my-bookings', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> checkAvailability({
    required int courtId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _dio.get('/booking/check-availability', queryParameters: {
        'courtId': courtId,  // Query parameters thường viết thường
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      });
      return response.data['isAvailable'] ?? false;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Admin endpoints
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    print('DioException details:'); // Debug log
    print('Type: ${error.type}');
    print('Message: ${error.message}');
    print('Response: ${error.response?.data}');
    print('Status Code: ${error.response?.statusCode}');
    
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        // Handle validation errors from ASP.NET Identity
        if (data.containsKey('') && data[''] is List) {
          final errors = data[''] as List;
          return errors.join('\n');
        }
        
        // Handle specific error messages
        if (data.containsKey('message')) {
          return data['message'];
        }
        
        // Handle ModelState errors
        if (data.containsKey('errors')) {
          final errors = data['errors'] as Map<String, dynamic>;
          final errorMessages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.cast<String>());
            }
          });
          if (errorMessages.isNotEmpty) {
            return errorMessages.join('\n');
          }
        }
        
        return data.toString();
      }
      return 'Có lỗi xảy ra: ${error.response!.statusCode}';
    }
    
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Kết nối timeout. Vui lòng thử lại.';
    }
    
    if (error.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
    }
    
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }
}