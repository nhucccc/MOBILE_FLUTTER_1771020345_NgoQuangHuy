import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_background.dart';
import 'recurring_booking_screen.dart';
import '../home/main_screen.dart';

class NewBookingScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const NewBookingScreen({
    super.key,
    this.selectedDate,
  });

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> 
    with TickerProviderStateMixin {
  Court? _selectedCourt;
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourts();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadCourts() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    if (bookingProvider.courts.isEmpty) {
      await bookingProvider.loadCourts();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Đang tải dữ liệu sân...',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: GlassCard(
          padding: const EdgeInsets.all(AppTheme.spacing32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              Text(
                'Có lỗi xảy ra',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadCourts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: GlassCard(
          padding: const EdgeInsets.all(AppTheme.spacing32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.neutral300,
                      AppTheme.neutral400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.sports_tennis,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              Text(
                'Không có sân nào',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.neutral700,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'Hiện tại chưa có sân nào khả dụng',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadCourts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingForm(BookingProvider bookingProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        kToolbarHeight + AppTheme.spacing32,
        AppTheme.spacing16,
        kBottomNavigationBarHeight + AppTheme.spacing32, // Thêm padding bottom cho bottom nav
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selection card
          _buildDateCard(),
          const SizedBox(height: AppTheme.spacing24),
          
          // Court selection
          _buildCourtSelection(bookingProvider),
          const SizedBox(height: AppTheme.spacing24),
          
          // Time selection
          _buildTimeSelection(),
          const SizedBox(height: AppTheme.spacing24),
          
          // Price calculation
          if (_selectedCourt != null) ...[
            _buildPriceCard(),
            const SizedBox(height: AppTheme.spacing32),
          ],
          
          // Book button
          _buildBookButton(),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return GlassCard(
      onTap: _selectDate,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ngày đặt sân',
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.edit_calendar,
            color: AppTheme.primaryColor.withOpacity(0.7),
            size: 20,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: AppTheme.primaryColor,
              headerForegroundColor: Colors.white,
              dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return AppTheme.neutral900;
              }),
              dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return AppTheme.primaryColor;
                }
                return null;
              }),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Đặt sân',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.neutral900,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.shadowSM,
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.shadowSM,
              ),
              child: const Icon(Icons.repeat, size: 20),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecurringBookingScreen(),
                ),
              );
            },
            tooltip: 'Đặt sân định kỳ',
          ),
        ],
      ),
      body: AnimatedBackground(
        primaryColor: AppTheme.primaryColor,
        secondaryColor: AppTheme.accentColor,
        child: Consumer<BookingProvider>(
          builder: (context, bookingProvider, child) {
            if (bookingProvider.isLoading) {
              return _buildLoadingState();
            }

            if (bookingProvider.error != null) {
              return _buildErrorState(bookingProvider.error!);
            }

            if (bookingProvider.courts.isEmpty) {
              return _buildEmptyState();
            }

            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBookingForm(bookingProvider),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCourtSelection(BookingProvider bookingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn sân',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.neutral900,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        GlassCard(
          child: Column(
            children: bookingProvider.courts.asMap().entries.map((entry) {
              final index = entry.key;
              final court = entry.value;
              final isSelected = _selectedCourt?.id == court.id;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  bottom: index < bookingProvider.courts.length - 1 
                      ? AppTheme.spacing12 
                      : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCourt = court;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    decoration: BoxDecoration(
                      gradient: isSelected 
                          ? AppTheme.primaryGradient
                          : LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.8),
                                Colors.white.withOpacity(0.6),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.primaryColor
                            : AppTheme.neutral200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? AppTheme.shadowMD : AppTheme.shadowSM,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.white.withOpacity(0.2)
                                : AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: Icon(
                            Icons.sports_tennis,
                            color: isSelected ? Colors.white : AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                court.name,
                                style: AppTheme.titleMedium.copyWith(
                                  color: isSelected ? Colors.white : AppTheme.neutral900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing4),
                              Text(
                                '${court.pricePerHour.toStringAsFixed(0)}đ/giờ',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: isSelected 
                                      ? Colors.white.withOpacity(0.9)
                                      : AppTheme.successColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: AppTheme.primaryColor,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    return Row(
      children: [
        Expanded(child: _buildTimeCard('Giờ bắt đầu', _startTime, true)),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(child: _buildTimeCard('Giờ kết thúc', _endTime, false)),
      ],
    );
  }

  Widget _buildTimeCard(String title, TimeOfDay time, bool isStartTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.neutral900,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        GlassCard(
          onTap: () => _selectTime(context, isStartTime),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  time.format(context),
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard() {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            child: const Icon(
              Icons.payments,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng chi phí',
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  '${_calculateTotalPrice().toStringAsFixed(0)}đ',
                  style: AppTheme.headlineMedium.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_calculateDuration().toStringAsFixed(1)} giờ × ${_selectedCourt!.pricePerHour.toStringAsFixed(0)}đ/giờ',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        child: ElevatedButton(
          onPressed: _selectedCourt != null && !_isLoading
              ? _createBooking
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
          ).copyWith(
            backgroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return AppTheme.neutral300;
                }
                return AppTheme.primaryColor;
              },
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_tennis, size: 20),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      'Đặt sân ngay',
                      style: AppTheme.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Auto adjust end time if needed
          if (_endTime.hour <= _startTime.hour) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 2) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  double _calculateDuration() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final durationMinutes = endMinutes > startMinutes 
        ? endMinutes - startMinutes 
        : (24 * 60) - startMinutes + endMinutes;
    return durationMinutes / 60.0;
  }

  double _calculateTotalPrice() {
    if (_selectedCourt == null) return 0;
    return _calculateDuration() * _selectedCourt!.pricePerHour;
  }

  Future<void> _createBooking() async {
    if (_selectedCourt == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      final user = authProvider.user;
      if (user?.member == null) {
        throw 'Không tìm thấy thông tin thành viên';
      }

      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      ).toUtc(); // Convert to UTC

      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      ).toUtc(); // Convert to UTC

      print('Creating booking:'); // Debug log
      print('Court ID: ${_selectedCourt!.id}');
      print('Start Time: ${startDateTime.toIso8601String()}');
      print('End Time: ${endDateTime.toIso8601String()}');

      final success = await bookingProvider.createBooking(
        courtId: _selectedCourt!.id,
        startTime: startDateTime,
        endTime: endDateTime,
        isRecurring: false,
        recurrenceRule: null,
        recurringEndDate: null,
      );

      if (success && mounted) {
        // Hiển thị dialog thành công
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              title: const Text(
                '🎉 Đặt sân thành công!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sân: ${_selectedCourt!.name}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thời gian: ${startDateTime.day}/${startDateTime.month}/${startDateTime.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_startTime.format(context)} - ${_endTime.format(context)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cảm ơn bạn đã sử dụng dịch vụ!',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng dialog
                    // Quay về trang chủ bằng cách pop tất cả
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'Về trang chủ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Booking error: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}