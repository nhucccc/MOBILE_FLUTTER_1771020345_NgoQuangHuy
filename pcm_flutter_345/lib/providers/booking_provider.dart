import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SignalRService _signalRService = SignalRService();

  List<Court> _courts = [];
  List<Booking> _calendarBookings = [];
  List<Booking> _myBookings = [];
  bool _isLoading = false;
  String? _error;

  List<Court> get courts => _courts;
  List<Booking> get calendarBookings => _calendarBookings;
  List<Booking> get myBookings => _myBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BookingProvider() {
    _setupSignalRListeners();
  }

  void _setupSignalRListeners() {
    _signalRService.bookingUpdateStream.listen((data) {
      // Reload calendar when updates are received
      loadCalendarBookings(
        from: DateTime.now().subtract(const Duration(days: 7)),
        to: DateTime.now().add(const Duration(days: 30)),
      );
    });
  }

  Future<void> loadCourts() async {
    _setLoading(true);
    _clearError();

    try {
      final courtData = await _apiService.getCourts();
      _courts = courtData.map((json) => Court.fromJson(json)).toList();
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
  }

  Future<void> loadCalendarBookings({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final bookingData = await _apiService.getCalendarBookings(
        from: from,
        to: to,
      );
      _calendarBookings = bookingData
          .map((json) => Booking.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> loadMyBookings({int page = 1, int pageSize = 20}) async {
    _setLoading(true);
    _clearError();

    try {
      final bookingData = await _apiService.getMyBookings(
        page: page,
        pageSize: pageSize,
      );
      
      final newBookings = bookingData
          .map((json) => Booking.fromJson(json))
          .toList();

      if (page == 1) {
        _myBookings = newBookings;
      } else {
        _myBookings.addAll(newBookings);
      }
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
  }

  Future<bool> createBooking({
    required int courtId,
    required DateTime startTime,
    required DateTime endTime,
    bool isRecurring = false,
    String? recurrenceRule,
    DateTime? recurringEndDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      print('BookingProvider: Creating booking...');
      print('Court ID: $courtId');
      print('Start: ${startTime.toIso8601String()}');
      print('End: ${endTime.toIso8601String()}');
      
      if (isRecurring && recurrenceRule != null && recurringEndDate != null) {
        await _apiService.createRecurringBooking(
          courtId: courtId,
          startTime: startTime,
          endTime: endTime,
          recurrenceRule: recurrenceRule,
          endDate: recurringEndDate,
        );
      } else {
        final result = await _apiService.createBooking(
          courtId: courtId,
          startTime: startTime,
          endTime: endTime,
        );
        print('BookingProvider: API result: $result');
      }

      // Reload bookings
      await Future.wait([
        loadMyBookings(),
        loadCalendarBookings(
          from: DateTime.now().subtract(const Duration(days: 7)),
          to: DateTime.now().add(const Duration(days: 30)),
        ),
      ]);

      _setLoading(false);
      return true;
    } catch (e) {
      print('BookingProvider: Error creating booking: $e');
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> createRecurringBooking({
    required int courtId,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required DateTime startDate,
    required DateTime endDate,
    required List<int> weekdays,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Convert TimeOfDay to DateTime for the first occurrence
      final firstStartTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        startTime.hour,
        startTime.minute,
      );
      
      final firstEndTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        endTime.hour,
        endTime.minute,
      );

      // Create recurrence rule string
      final weekdayNames = weekdays.map((w) {
        switch (w) {
          case 1: return 'MO';
          case 2: return 'TU';
          case 3: return 'WE';
          case 4: return 'TH';
          case 5: return 'FR';
          case 6: return 'SA';
          case 7: return 'SU';
          default: return '';
        }
      }).where((w) => w.isNotEmpty).join(',');
      
      final recurrenceRule = 'FREQ=WEEKLY;BYDAY=$weekdayNames';

      await _apiService.createRecurringBooking(
        courtId: courtId,
        startTime: firstStartTime,
        endTime: firstEndTime,
        recurrenceRule: recurrenceRule,
        endDate: endDate,
      );

      // Reload bookings
      await Future.wait([
        loadMyBookings(),
        loadCalendarBookings(
          from: DateTime.now().subtract(const Duration(days: 7)),
          to: DateTime.now().add(const Duration(days: 30)),
        ),
      ]);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> cancelBooking(int bookingId) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.cancelBooking(bookingId);

      // Remove from local lists
      _myBookings.removeWhere((b) => b.id == bookingId);
      _calendarBookings.removeWhere((b) => b.id == bookingId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> checkAvailability({
    required int courtId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      return await _apiService.checkAvailability(
        courtId: courtId,
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e) {
      _setError(e.toString());
      return false;
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

  // Helper methods
  List<Booking> getBookingsForDate(DateTime date) {
    return _calendarBookings.where((booking) {
      final bookingDate = DateTime(
        booking.startTime.year,
        booking.startTime.month,
        booking.startTime.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return bookingDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  List<Booking> getBookingsForCourt(int courtId, DateTime date) {
    return getBookingsForDate(date)
        .where((booking) => booking.courtId == courtId)
        .toList();
  }

  Court? getCourtById(int courtId) {
    try {
      return _courts.firstWhere((court) => court.id == courtId);
    } catch (e) {
      return null;
    }
  }

  List<Booking> get upcomingBookings {
    final now = DateTime.now();
    return _myBookings
        .where((booking) => booking.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<Booking> get todayBookings {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return _myBookings
        .where((booking) => 
            booking.startTime.isAfter(todayStart) && 
            booking.startTime.isBefore(todayEnd))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
}