import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/theme_config.dart';
import '../../../core/config/app_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../../booking/providers/booking_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../shared/widgets/loading_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    walletProvider.loadWalletBalance();
    bookingProvider.loadMyBookings(pageSize: 5);
    bookingProvider.loadCourts();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final member = user?.member;

        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          child: RefreshIndicator(
            onRefresh: () async {
              await authProvider.refreshUserData();
              _loadData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  _buildWelcomeCard(user?.fullName ?? 'Người dùng', member),
                  const SizedBox(height: 16),

                  // Quick Stats
                  _buildQuickStats(),
                  const SizedBox(height: 16),

                  // Wallet Balance Chart
                  _buildWalletChart(),
                  const SizedBox(height: 16),

                  // Recent Bookings
                  _buildRecentBookings(),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(String userName, dynamic member) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [ThemeConfig.primaryColor, ThemeConfig.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chào mừng trở lại!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Color(AppConfig.tierColors[member?.tier] ?? 0xFFFFFFFF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member?.tier ?? 'Standard',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rank: ${member?.rankLevel?.toStringAsFixed(1) ?? '0.0'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer2<WalletProvider, BookingProvider>(
      builder: (context, walletProvider, bookingProvider, child) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Số dư ví',
                '${walletProvider.balance?.toStringAsFixed(0) ?? '0'}đ',
                Icons.account_balance_wallet,
                ThemeConfig.walletGreen,
                () => context.push('/wallet'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Lịch đặt',
                '${bookingProvider.myBookings.length}',
                Icons.calendar_today,
                ThemeConfig.primaryColor,
                () => context.push('/booking'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletChart() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final transactions = walletProvider.walletBalance?.recentTransactions ?? [];
        
        if (transactions.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Biểu đồ giao dịch',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chưa có giao dịch nào'),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giao dịch gần đây',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: transactions.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value.amount);
                          }).toList(),
                          isCurved: true,
                          color: ThemeConfig.primaryColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: ThemeConfig.primaryColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentBookings() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        final bookings = bookingProvider.myBookings.take(3).toList();
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lịch đặt gần đây',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/booking'),
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (bookings.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Chưa có lịch đặt nào'),
                    ),
                  )
                else
                  ...bookings.map((booking) => _buildBookingItem(booking)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingItem(dynamic booking) {
    final startTime = DateTime.parse(booking['startTime']);
    final endTime = DateTime.parse(booking['endTime']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(booking['status']),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['courtName'],
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${startTime.day}/${startTime.month} • ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${booking['totalPrice'].toStringAsFixed(0)}đ',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return ThemeConfig.successColor;
      case 'pending':
        return ThemeConfig.warningColor;
      case 'cancelled':
        return ThemeConfig.errorColor;
      default:
        return Colors.grey;
    }
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thao tác nhanh',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Đặt sân',
                    Icons.calendar_today,
                    ThemeConfig.primaryColor,
                    () => context.push('/booking'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Nạp tiền',
                    Icons.add_card,
                    ThemeConfig.walletGreen,
                    () => context.push('/wallet/deposit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Giải đấu',
                    Icons.emoji_events,
                    ThemeConfig.warningColor,
                    () => context.push('/tournaments'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Thành viên',
                    Icons.group,
                    ThemeConfig.infoColor,
                    () => context.push('/members'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}