import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';

class RecurringBookingScreen extends StatefulWidget {
  const RecurringBookingScreen({super.key});

  @override
  State<RecurringBookingScreen> createState() => _RecurringBookingScreenState();
}

class _RecurringBookingScreenState extends State<RecurringBookingScreen> {
  int? _selectedCourtId;
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  
  final Set<int> _selectedWeekdays = <int>{};
  bool _isLoading = false;

  final Map<int, String> _weekdayNames = {
    1: 'Thứ 2',
    2: 'Thứ 3', 
    3: 'Thứ 4',
    4: 'Thứ 5',
    5: 'Thứ 6',
    6: 'Thứ 7',
    7: 'Chủ nhật',
  };

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    if (bookingProvider.courts.isEmpty) {
      await bookingProvider.loadCourts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lịch định kỳ'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, kBottomNavigationBarHeight + 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // VIP Notice
                SimpleCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: AppTheme.warningColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tính năng VIP',
                              style: AppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warningColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chỉ dành cho thành viên hạng Vàng trở lên',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Court Selection
                _buildCourtSelection(bookingProvider),
                
                const SizedBox(height: 24),
                
                // Time Selection
                _buildTimeSelection(),
                
                const SizedBox(height: 24),
                
                // Date Range
                _buildDateRangeSelection(),
                
                const SizedBox(height: 24),
                
                // Weekday Selection
                _buildWeekdaySelection(),
                
                const SizedBox(height: 24),
                
                // Summary
                if (_selectedCourtId != null && _selectedWeekdays.isNotEmpty)
                  _buildSummary(bookingProvider),
                
                const SizedBox(height: 32),
                
                // Create Button
                _buildCreateButton(),
              ],
            ),
          );
        },
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
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SimpleCard(
          child: Column(
            children: bookingProvider.courts.asMap().entries.map((entry) {
              final index = entry.key;
              final court = entry.value;
              final isSelected = _selectedCourtId == court.id;
              
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor 
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.sports_tennis,
                        color: isSelected ? Colors.white : AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      court.name,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${court.pricePerHour.toStringAsFixed(0)}đ/giờ',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCourtId = court.id;
                      });
                    },
                  ),
                  if (index < bookingProvider.courts.length - 1)
                    const Divider(height: 1),
                ],
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
        Expanded(
          child: _buildTimeCard('Giờ bắt đầu', _startTime, true),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTimeCard('Giờ kết thúc', _endTime, false),
        ),
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
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SimpleCard(
          onTap: () => _selectTime(context, isStartTime),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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

  Widget _buildDateRangeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khoảng thời gian',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateCard('Từ ngày', _startDate, true),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateCard('Đến ngày', _endDate, false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateCard(String title, DateTime date, bool isStartDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SimpleCard(
          onTap: () => _selectDate(context, isStartDate),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${date.day}/${date.month}/${date.year}',
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

  Widget _buildWeekdaySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn ngày trong tuần',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SimpleCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekdayNames.entries.map((entry) {
              final weekday = entry.key;
              final name = entry.value;
              final isSelected = _selectedWeekdays.contains(weekday);
              
              return FilterChip(
                label: Text(name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedWeekdays.add(weekday);
                    } else {
                      _selectedWeekdays.remove(weekday);
                    }
                  });
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(BookingProvider bookingProvider) {
    final court = bookingProvider.courts.firstWhere((c) => c.id == _selectedCourtId);
    final duration = _calculateDuration();
    final totalSessions = _calculateTotalSessions();
    final totalCost = duration * court.pricePerHour * totalSessions;
    
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tóm tắt đặt lịch',
            style: AppTheme.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Sân:', court.name),
          _buildSummaryRow('Thời gian:', '${_startTime.format(context)} - ${_endTime.format(context)}'),
          _buildSummaryRow('Ngày:', _selectedWeekdays.map((w) => _weekdayNames[w]).join(', ')),
          _buildSummaryRow('Khoảng thời gian:', '${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}'),
          _buildSummaryRow('Tổng số buổi:', '$totalSessions buổi'),
          const Divider(),
          _buildSummaryRow(
            'Tổng chi phí:', 
            '${totalCost.toStringAsFixed(0)}đ',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal 
                ? AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold)
                : AppTheme.bodyMedium,
          ),
          Text(
            value,
            style: isTotal 
                ? AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  )
                : AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    final canCreate = _selectedCourtId != null && _selectedWeekdays.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canCreate && !_isLoading ? _createRecurringBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.repeat, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tạo lịch định kỳ',
                    style: AppTheme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
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

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
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

  int _calculateTotalSessions() {
    int sessions = 0;
    DateTime current = _startDate;
    
    while (current.isBefore(_endDate) || current.isAtSameMomentAs(_endDate)) {
      if (_selectedWeekdays.contains(current.weekday)) {
        sessions++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return sessions;
  }

  Future<void> _createRecurringBooking() async {
    if (_selectedCourtId == null || _selectedWeekdays.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      final success = await bookingProvider.createRecurringBooking(
        courtId: _selectedCourtId!,
        startTime: _startTime,
        endTime: _endTime,
        startDate: _startDate,
        endDate: _endDate,
        weekdays: _selectedWeekdays.toList(),
      );

      if (success && mounted) {
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
      builder: (context) => AlertDialog(
        title: const Text('Thành công!'),
        content: const Text('Lịch định kỳ đã được tạo thành công.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close screen
            },
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}