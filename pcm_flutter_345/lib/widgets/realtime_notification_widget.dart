import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/signalr_service.dart';

class RealtimeNotificationWidget extends StatefulWidget {
  final Widget child;
  
  const RealtimeNotificationWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<RealtimeNotificationWidget> createState() => _RealtimeNotificationWidgetState();
}

class _RealtimeNotificationWidgetState extends State<RealtimeNotificationWidget> {
  SignalRService? _signalRService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSignalRListeners();
    });
  }

  void _setupSignalRListeners() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _signalRService = authProvider.signalRService;

    if (_signalRService != null) {
      // Listen to notifications
      _signalRService!.notificationStream.listen((data) {
        _showNotificationSnackBar(data);
      });

      // Listen to wallet updates
      _signalRService!.walletUpdateStream.listen((data) {
        _handleWalletUpdate(data);
      });

      // Listen to booking updates
      _signalRService!.bookingUpdateStream.listen((data) {
        _handleBookingUpdate(data);
      });

      // Listen to slot status changes
      _signalRService!.slotStatusStream.listen((data) {
        _handleSlotStatusChange(data);
      });

      // Listen to tournament updates
      _signalRService!.tournamentUpdateStream.listen((data) {
        _handleTournamentUpdate(data);
      });
    }
  }

  void _showNotificationSnackBar(Map<String, dynamic> data) {
    if (!mounted) return;

    final title = data['title'] ?? 'Thông báo';
    final message = data['message'] ?? '';
    final type = data['type'] ?? 'info';

    Color backgroundColor;
    IconData icon;

    switch (type.toLowerCase()) {
      case 'success':
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'warning':
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case 'error':
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      default:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleWalletUpdate(Map<String, dynamic> data) {
    if (!mounted) return;

    final type = data['type'];
    
    if (type == 'deposit_approved') {
      final amount = data['data']['amount'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ Nạp tiền thành công: ${amount.toStringAsFixed(0)}đ',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (type == 'deposit_rejected') {
      final amount = data['data']['amount'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '❌ Nạp tiền bị từ chối: ${amount.toStringAsFixed(0)}đ',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Regular wallet balance update
      final balance = data['balance'] ?? 0;
      final amount = data['amount'] ?? 0;
      final transactionType = data['transactionType'] ?? '';
      
      if (transactionType.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '💰 Ví cập nhật: ${balance.toStringAsFixed(0)}đ',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleBookingUpdate(Map<String, dynamic> data) {
    if (!mounted) return;

    final type = data['type'];
    
    if (type == 'booking_created') {
      final courtName = data['data']['courtName'] ?? 'Sân';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sports_tennis, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🏟️ Đặt sân thành công: $courtName',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (type == 'booking_cancelled') {
      final courtName = data['data']['courtName'] ?? 'Sân';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '❌ Đã hủy đặt sân: $courtName',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleSlotStatusChange(Map<String, dynamic> data) {
    if (!mounted) return;

    final courtId = data['courtId'] ?? 0;
    final status = data['status'] ?? '';
    final type = data['type'];
    
    if (type == 'slot_expired') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.timer_off, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⏰ Slot sân $courtId đã hết hạn',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleTournamentUpdate(Map<String, dynamic> data) {
    if (!mounted) return;

    final type = data['type'];
    
    if (type == 'registration_opened') {
      final name = data['data']['name'] ?? 'Giải đấu';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🏆 Mở đăng ký: $name',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.purple,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (type == 'match_score_updated') {
      final matchId = data['data']['matchId'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sports_score, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚽ Cập nhật tỷ số trận $matchId',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}