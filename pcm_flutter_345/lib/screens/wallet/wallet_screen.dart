import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/modern_stats_card.dart';
import 'deposit_screen.dart';
import 'wallet_history_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).refreshBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AnimatedBackground(
        primaryColor: AppTheme.successColor,
        secondaryColor: AppTheme.primaryColor,
        child: SafeArea(
          child: Consumer<WalletProvider>(
            builder: (context, walletProvider, child) {
              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ví điện tử',
                            style: AppTheme.headlineLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neutral900,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing8),
                          Text(
                            'Quản lý tài chính của bạn',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Balance Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
                      child: GlassCard(
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacing24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.successColor.withOpacity(0.1),
                                AppTheme.primaryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.7)],
                                      ),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => walletProvider.refreshBalance(),
                                    icon: const Icon(Icons.refresh),
                                    color: AppTheme.successColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacing20),
                              Text(
                                'Số dư hiện tại',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.neutral600,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing8),
                              Text(
                                '${walletProvider.balance.toStringAsFixed(0)}đ',
                                style: AppTheme.displayMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Quick Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thao tác nhanh',
                            style: AppTheme.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          Row(
                            children: [
                              Expanded(
                                child: GlassCard(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const DepositScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(AppTheme.spacing20),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: AppTheme.primaryGradient,
                                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                          ),
                                          child: const Icon(
                                            Icons.add_card,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: AppTheme.spacing12),
                                        Text(
                                          'Nạp tiền',
                                          style: AppTheme.titleSmall.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing16),
                              Expanded(
                                child: GlassCard(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const WalletHistoryScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(AppTheme.spacing20),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [AppTheme.infoColor, AppTheme.infoColor.withOpacity(0.7)],
                                            ),
                                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                          ),
                                          child: const Icon(
                                            Icons.history,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: AppTheme.spacing12),
                                        Text(
                                          'Lịch sử',
                                          style: AppTheme.titleSmall.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Recent Transactions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacing24,
                        AppTheme.spacing24,
                        AppTheme.spacing24,
                        kBottomNavigationBarHeight + AppTheme.spacing32, // Thêm padding bottom cho bottom nav
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giao dịch gần đây',
                            style: AppTheme.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          GlassCard(
                            child: Column(
                              children: [
                                _buildTransactionItem(
                                  icon: Icons.add_circle,
                                  title: 'Nạp tiền',
                                  subtitle: 'VNPay',
                                  amount: '+500.000đ',
                                  time: '2 giờ trước',
                                  isPositive: true,
                                ),
                                const Divider(height: 1),
                                _buildTransactionItem(
                                  icon: Icons.sports_tennis,
                                  title: 'Đặt sân A',
                                  subtitle: '14:00 - 16:00',
                                  amount: '-200.000đ',
                                  time: '1 ngày trước',
                                  isPositive: false,
                                ),
                                const Divider(height: 1),
                                _buildTransactionItem(
                                  icon: Icons.add_circle,
                                  title: 'Nạp tiền',
                                  subtitle: 'Chuyển khoản',
                                  amount: '+1.000.000đ',
                                  time: '3 ngày trước',
                                  isPositive: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required String time,
    required bool isPositive,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPositive
                    ? [AppTheme.successColor, AppTheme.successColor.withOpacity(0.7)]
                    : [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Icon(
              icon,
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
                  title,
                  style: AppTheme.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTheme.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                time,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.neutral500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}