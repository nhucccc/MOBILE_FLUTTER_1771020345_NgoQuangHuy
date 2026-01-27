import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_background.dart';

class CreateBookingScreen extends StatefulWidget {
  final DateTime selectedDate;

  const CreateBookingScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> 
    with TickerProviderStateMixin {
  Court? _selectedCourt;
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourts();
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
              'Đang tải dữ liệu...',
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
        AppTheme.spacing24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date info card
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
    return AnimatedGlassCard(
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
                  '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        AnimatedGlassCard(
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
        AnimatedGlassCard(
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
    return AnimatedGlassCard(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Đặt sân mới',
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
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildBookingForm(bookingProvider),
              ),
            );
          },
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
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final success = await bookingProvider.createBooking(
        courtId: _selectedCourt!.id,
        startTime: startDateTime,
        endTime: endDateTime,
        isRecurring: false,
        recurrenceRule: null,
        recurringEndDate: null,
      );

      if (success && mounted) {
        // Show success animation
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(AppTheme.spacing32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              Text(
                'Đặt sân thành công!',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'Booking của bạn đã được tạo thành công',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close screen
                  },
                  child: const Text('Hoàn tất'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        margin: const EdgeInsets.all(AppTheme.spacing16),
      ),
    );
  }
}