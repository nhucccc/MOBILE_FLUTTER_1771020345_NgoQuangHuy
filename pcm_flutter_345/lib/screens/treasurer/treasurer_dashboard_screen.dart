import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/role_badge.dart';

class TreasurerDashboardScreen extends StatefulWidget {
  const TreasurerDashboardScreen({super.key});

  @override
  State<TreasurerDashboardScreen> createState() => _TreasurerDashboardScreenState();
}

class _TreasurerDashboardScreenState extends State<TreasurerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: CustomScrollView(
            slivers: [
              // Treasurer Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.treasurerGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.account_balance,
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
                                    'Bảng điều khiển Kế toán',
                                    style: AppTheme.headingMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Quản lý tài chính và báo cáo',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        RoleBadge(
                          role: user?.role,
                          showDescription: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Financial Overview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng quan tài chính',
                        style: AppTheme.headingMedium,
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.5,
                        children: [
                          StatsCard(
                            title: 'Doanh thu hôm nay',
                            value: '12.5M',
                            icon: Icons.today,
                            color: AppTheme.successColor,
                            subtitle: '+8% so với hôm qua',
                            onTap: () => _navigateToDailyReport(),
                          ),
                          StatsCard(
                            title: 'Doanh thu tháng',
                            value: '125M',
                            icon: Icons.calendar_month,
                            color: AppTheme.treasurerColor,
                            subtitle: '+15% so với tháng trước',
                            onTap: () => _navigateToMonthlyReport(),
                          ),
                          StatsCard(
                            title: 'Tổng nạp tiền',
                            value: '45.2M',
                            icon: Icons.add_card,
                            color: AppTheme.infoColor,
                            subtitle: '234 giao dịch',
                            onTap: () => _navigateToTopUpReport(),
                          ),
                          StatsCard(
                            title: 'Chi phí vận hành',
                            value: '8.7M',
                            icon: Icons.trending_down,
                            color: AppTheme.warningColor,
                            subtitle: 'Điện, nước, bảo trì',
                            onTap: () => _navigateToExpenseReport(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Financial Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quản lý tài chính',
                        style: AppTheme.headingMedium,
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.2,
                        children: [
                          ActionCard(
                            title: 'Báo cáo doanh thu',
                            description: 'Xem báo cáo chi tiết',
                            icon: Icons.assessment,
                            color: AppTheme.treasurerColor,
                            onTap: () => _navigateToRevenueReport(),
                          ),
                          ActionCard(
                            title: 'Xuất Excel',
                            description: 'Xuất dữ liệu ra Excel',
                            icon: Icons.file_download,
                            color: AppTheme.treasurerColor,
                            onTap: () => _exportToExcel(),
                          ),
                          ActionCard(
                            title: 'Quản lý giao dịch',
                            description: 'Xem tất cả giao dịch',
                            icon: Icons.receipt_long,
                            color: AppTheme.treasurerColor,
                            onTap: () => _navigateToTransactions(),
                          ),
                          ActionCard(
                            title: 'Cài đặt giá',
                            description: 'Cập nhật giá sân',
                            icon: Icons.price_change,
                            color: AppTheme.treasurerColor,
                            onTap: () => _navigateToPriceSettings(),
                          ),
                          ActionCard(
                            title: 'Thống kê thành viên',
                            description: 'Phân tích chi tiêu',
                            icon: Icons.people_alt,
                            color: AppTheme.treasurerColor,
                            onTap: () => _navigateToMemberStats(),
                          ),
                          ActionCard(
                            title: 'Báo cáo thuế',
                            description: 'Chuẩn bị báo cáo thuế',
                            icon: Icons.account_balance_wallet,
                            color: AppTheme.treasurerColor,
                            onTap: () => _navigateToTaxReport(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Recent Financial Activities
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giao dịch gần đây',
                        style: AppTheme.headingMedium,
                      ),
                      const SizedBox(height: 16),
                      CustomCard(
                        child: Column(
                          children: [
                            _buildTransactionItem(
                              icon: Icons.add_card,
                              title: 'Nạp tiền',
                              subtitle: 'Nguyễn Văn A - 500.000đ',
                              time: '5 phút trước',
                              color: AppTheme.successColor,
                              amount: '+500.000đ',
                            ),
                            const Divider(),
                            _buildTransactionItem(
                              icon: Icons.sports_tennis,
                              title: 'Thanh toán booking',
                              subtitle: 'Sân A - 2 giờ',
                              time: '15 phút trước',
                              color: AppTheme.infoColor,
                              amount: '-300.000đ',
                            ),
                            const Divider(),
                            _buildTransactionItem(
                              icon: Icons.emoji_events,
                              title: 'Phí tham gia giải đấu',
                              subtitle: 'Giải đấu mùa xuân',
                              time: '1 giờ trước',
                              color: AppTheme.warningColor,
                              amount: '-100.000đ',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom padding for navigation bar
              const SliverToBoxAdapter(
                child: SizedBox(height: kBottomNavigationBarHeight + 32),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
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
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall,
                ),
                Text(
                  time,
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: amount.startsWith('+') 
                ? AppTheme.successColor 
                : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToDailyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Báo cáo doanh thu hôm nay')),
    );
  }

  void _navigateToMonthlyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Báo cáo doanh thu tháng')),
    );
  }

  void _navigateToTopUpReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Báo cáo nạp tiền')),
    );
  }

  void _navigateToExpenseReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Báo cáo chi phí')),
    );
  }

  void _navigateToRevenueReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Báo cáo doanh thu chi tiết')),
    );
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Xuất dữ liệu ra Excel')),
    );
  }

  void _navigateToTransactions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quản lý giao dịch')),
    );
  }

  void _navigateToPriceSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cài đặt giá sân')),
    );
  }

  void _navigateToMemberStats() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thống kê thành viên')),
    );
  }

  void _navigateToTaxReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Báo cáo thuế')),
    );
  }
}