import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/wallet.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          if (walletProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (walletProvider.error != null) {
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
                    walletProvider.error!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => walletProvider.loadTransactions(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (walletProvider.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: AppTheme.neutral400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có giao dịch nào',
                    style: AppTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Lịch sử giao dịch sẽ hiển thị tại đây'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => walletProvider.loadTransactions(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                kBottomNavigationBarHeight + 32,
              ),
              itemCount: walletProvider.transactions.length,
              itemBuilder: (context, index) {
                final transaction = walletProvider.transactions[index];
                return _buildTransactionCard(transaction);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction transaction) {
    final isPositive = transaction.type.toLowerCase() == 'deposit';
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (transaction.status.toLowerCase()) {
      case 'completed':
        statusColor = AppTheme.successColor;
        statusText = 'Hoàn thành';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppTheme.warningColor;
        statusText = 'Chờ xử lý';
        statusIcon = Icons.schedule;
        break;
      case 'failed':
        statusColor = AppTheme.errorColor;
        statusText = 'Thất bại';
        statusIcon = Icons.error;
        break;
      case 'cancelled':
        statusColor = AppTheme.neutral500;
        statusText = 'Đã hủy';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppTheme.neutral500;
        statusText = transaction.status;
        statusIcon = Icons.info;
    }

    IconData transactionIcon;
    Color transactionColor;
    
    switch (transaction.type.toLowerCase()) {
      case 'deposit':
        transactionIcon = Icons.add_circle;
        transactionColor = AppTheme.successColor;
        break;
      case 'payment':
        transactionIcon = Icons.remove_circle;
        transactionColor = AppTheme.errorColor;
        break;
      case 'refund':
        transactionIcon = Icons.refresh;
        transactionColor = AppTheme.infoColor;
        break;
      default:
        transactionIcon = Icons.swap_horiz;
        transactionColor = AppTheme.neutral500;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SimpleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với icon và trạng thái
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: transactionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    transactionIcon,
                    color: transactionColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTransactionTitle(transaction.type),
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${transaction.id}',
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
            
            // Mô tả
            if (transaction.description.isNotEmpty) ...[
              Text(
                transaction.description,
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],
            
            // Thông tin số tiền và thời gian
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số tiền',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.neutral600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isPositive ? '+' : '-'}${transaction.amount.toStringAsFixed(0)}đ',
                        style: AppTheme.titleMedium.copyWith(
                          color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Thời gian',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.neutral600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(transaction.createdDate),
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Thông tin bổ sung nếu có
            if (transaction.relatedId != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: AppTheme.neutral600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mã tham chiếu: ${transaction.relatedId}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.neutral600,
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

  String _getTransactionTitle(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return 'Nạp tiền';
      case 'payment':
        return 'Thanh toán';
      case 'refund':
        return 'Hoàn tiền';
      case 'withdrawal':
        return 'Rút tiền';
      default:
        return type;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}