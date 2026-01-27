import 'package:flutter/material.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Court> _courts = [];
  List<CalendarBooking> _calendarBookings = [];
  List<Booking> _myBookings = [];
  bool _isLoading = false;
  String? _error;

  BookingProvider(this._apiService);

  // Getters
  List<Court> get courts => _courts;
  List<CalendarBooking> get calendarBookings => _calendarBookings;
  List<Booking> get myBookings => _myBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCourts() async {
    try {
      final response = await _apiService.get<List<dynamic>>('/api/booking/courts');
      _courts = (response.data as List)
          .map((json) => Court.fromJson(json))
          .toList();
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Lỗi tải danh sách sân: ${e.toString()}');
    }
  }

  Future<void> loadCalendarBookings(DateTime from, DateTime to) async {
    _setLoading(true);
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/api/booking/calendar',
        queryParameters: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        },
      );
      
      _calendarBookings = (response.data as List)
          .map((json) => CalendarBooking.fromJson(json))
          .toList();
      _clearError();
    } catch (e) {
      _setError('Lỗi tải lịch đặt sân: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMyBookings({int page = 1, int pageSize = 20}) async {
    if (page == 1) _setLoading(true);
    
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/api/booking/my-bookings',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      
      final newBookings = (response.data as List)
          .map((json) => Booking.fromJson(json))
          .toList();
      
      if (page == 1) {
        _myBookings = newBookings;
      } else {
        _myBookings.addAll(newBookings);
      }
      
      _clearError();
    } catch (e) {
      _setError('Lỗi tải lịch sử đặt sân: ${e.toString()}');
    } finally {
      if (page == 1) _setLoading(false);
    }
  }

  Future<bool> createBooking(CreateBookingRequest request) async {
    _setLoading(true);
    try {
      await _apiService.post<Map<String, dynamic>>(
        '/api/booking',
        data: request.toJson(),
      );
      
      // Reload calendar and my bookings
      await Future.wait([
        loadCalendarBookings(
          DateTime.now().subtract(const Duration(days: 7)),
          DateTime.now().add(const Duration(days: 30)),
        ),
        loadMyBookings(),
      ]);
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Lỗi đặt sân: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createRecurringBooking(CreateRecurringBookingRequest request) async {
    _setLoading(true);
    try {
      await _apiService.post<Map<String, dynamic>>(
        '/api/booking/recurring',
        data: request.toJson(),
      );
      
      // Reload calendar and my bookings
      await Future.wait([
        loadCalendarBookings(
          DateTime.now().subtract(const Duration(days: 7)),
          DateTime.now().add(const Duration(days: 30)),
        ),
        loadMyBookings(),
      ]);
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Lỗi đặt sân định kỳ: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelBooking(int bookingId) async {
    _setLoading(true);
    try {
      await _apiService.post<Map<String, dynamic>>('/api/booking/cancel/$bookingId');
      
      // Reload calendar and my bookings
      await Future.wait([
        loadCalendarBookings(
          DateTime.now().subtract(const Duration(days: 7)),
          DateTime.now().add(const Duration(days: 30)),
        ),
        loadMyBookings(),
      ]);
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Lỗi hủy đặt sân: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkAvailability(int courtId, DateTime startTime, DateTime endTime) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/booking/check-availability',
        queryParameters: {
          'courtId': courtId,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
        },
      );
      
      return response.data?['isAvailable'] ?? false;
    } catch (e) {
      return false;
    }
  }

  void updateCalendarFromSignalR(dynamic calendarData) {
    // Handle real-time calendar updates
    loadCalendarBookings(
      DateTime.now().subtract(const Duration(days: 7)),
      DateTime.now().add(const Duration(days: 30)),
    );
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
}