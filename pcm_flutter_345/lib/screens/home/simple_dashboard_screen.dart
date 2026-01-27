import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';
import '../../widgets/role_badge.dart';
import '../booking/booking_history_screen.dart';

class SimpleDashboardScreen extends StatefulWidget {
  const SimpleDashboardScreen({super.key});

  @override
  State<SimpleDashboardScreen> createState() => _SimpleDashboardScreenState();
}

class _SimpleDashboardScreenState extends State<SimpleDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    // Use Future.microtask to avoid setState during build
    await Future.microtask(() async {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      await Future.wait([
        walletProvider.loadWalletData(),
        bookingProvider.loadMyBookings(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.user;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, kBottomNavigationBarHeight + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  SimpleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.primaryColor,
                              child: user?.avatarUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      child: Image.network(
                                        user!.avatarUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xin chào!',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.fullName ?? 'Người dùng',
                                    style: AppTheme.headlineMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            RoleBadge(role: user?.role),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Cards
                  Text(
                    'Thống kê',
                    style: AppTheme.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Consumer2<WalletProvider, BookingProvider>(
                    builder: (context, walletProvider, bookingProvider, child) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Số dư ví',
                                  value: '${walletProvider.balance.toStringAsFixed(0)}đ',
                                  icon: Icons.account_balance_wallet,
                                  color: AppTheme.successColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Lượt đặt sân',
                                  value: '${bookingProvider.myBookings.length}',
                                  icon: Icons.sports_tennis,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Sân đã đặt',
                                  value: '${bookingProvider.myBookings.where((b) => b.status == 'Confirmed').length}',
                                  icon: Icons.check_circle,
                                  color: AppTheme.infoColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Đang chờ',
                                  value: '${bookingProvider.myBookings.where((b) => b.status == 'Pending').length}',
                                  icon: Icons.pending,
                                  color: AppTheme.warningColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  Text(
                    'Thao tác nhanh',
                    style: AppTheme.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          title: 'Đặt sân',
                          icon: Icons.sports_tennis,
                          color: AppTheme.primaryColor,
                          onTap: () {
                            // Navigate to booking
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionCard(
                          title: 'Giải đấu',
                          icon: Icons.emoji_events,
                          color: AppTheme.warningColor,
                          onTap: () {
                            Navigator.pushNamed(context, '/tournaments');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          title: 'Nạp tiền',
                          icon: Icons.add_card,
                          color: AppTheme.successColor,
                          onTap: () {
                            // Navigate to wallet
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionCard(
                          title: 'Lịch sử',
                          icon: Icons.history,
                          color: AppTheme.infoColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BookingHistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Activities
                  Text(
                    'Hoạt động gần đây',
                    style: AppTheme.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Consumer<BookingProvider>(
                    builder: (context, bookingProvider, child) {
                      final recentBookings = bookingProvider.myBookings.take(3).toList();
                      
                      if (recentBookings.isEmpty) {
                        return SimpleCard(
                          child: Column(
                            children: [
                              Icon(
                                Icons.sports_tennis,
                                size: 48,
                                color: AppTheme.neutral400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có hoạt động nào',
                                style: AppTheme.titleMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return SimpleCard(
                        child: Column(
                          children: recentBookings.asMap().entries.map((entry) {
                            final index = entry.key;
                            final booking = entry.value;
                            
                            return Column(
                              children: [
                                _buildActivityItem(
                                  title: 'Đặt sân ${booking.court?.name ?? 'N/A'}',
                                  subtitle: '${booking.startTime.day}/${booking.startTime.month}/${booking.startTime.year}',
                                  status: booking.status,
                                ),
                                if (index < recentBookings.length - 1)
                                  const Divider(),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SimpleCard(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String status,
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = AppTheme.successColor;
        break;
      case 'pending':
        statusColor = AppTheme.warningColor;
        break;
      case 'cancelled':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = AppTheme.neutral500;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.sports_tennis,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: AppTheme.labelSmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}