import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).loadMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đặt sân'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (bookingProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra',
                    style: AppTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bookingProvider.error!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => bookingProvider.loadMyBookings(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (bookingProvider.myBookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_tennis,
                    size: 64,
                    color: AppTheme.neutral400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có lịch sử đặt sân',
                    style: AppTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Hãy đặt sân đầu tiên của bạn!'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => bookingProvider.loadMyBookings(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                kBottomNavigationBarHeight + 32,
              ),
              itemCount: bookingProvider.myBookings.length,
              itemBuilder: (context, index) {
                final booking = bookingProvider.myBookings[index];
                return _buildBookingCard(booking, bookingProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, BookingProvider bookingProvider) {
    final court = bookingProvider.getCourtById(booking.courtId);
    final isUpcoming = booking.startTime.isAfter(DateTime.now());
    final isPast = booking.endTime.isBefore(DateTime.now());
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (booking.status.toLowerCase()) {
      case 'confirmed':
        statusColor = AppTheme.successColor;
        statusText = 'Đã xác nhận';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppTheme.warningColor;
        statusText = 'Chờ xác nhận';
        statusIcon = Icons.schedule;
        break;
      case 'cancelled':
        statusColor = AppTheme.errorColor;
        statusText = 'Đã hủy';
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = AppTheme.infoColor;
        statusText = 'Hoàn thành';
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = AppTheme.neutral500;
        statusText = booking.status;
        statusIcon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SimpleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với tên sân và trạng thái
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        court?.name ?? 'Sân #${booking.courtId}',
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking #${booking.id}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: AppTheme.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Thông tin thời gian
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${booking.startTime.day}/${booking.startTime.month}/${booking.startTime.year}',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Thông tin giá
            Row(
              children: [
                Icon(
                  Icons.payments,
                  size: 16,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${booking.totalPrice.toStringAsFixed(0)}đ',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (booking.isRecurring)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 12,
                          color: AppTheme.infoColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Định kỳ',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.infoColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            // Nút hành động
            if (isUpcoming && booking.status.toLowerCase() == 'confirmed') ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(booking, bookingProvider),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy đặt sân'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(color: AppTheme.errorColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showCancelDialog(Booking booking, BookingProvider bookingProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đặt sân'),
        content: const Text('Bạn có chắc chắn muốn hủy đặt sân này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await bookingProvider.cancelBooking(booking.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã hủy đặt sân thành công'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: ${bookingProvider.error ?? "Không thể hủy đặt sân"}'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy đặt sân'),
          ),
        ],
      ),
    );
  }
}