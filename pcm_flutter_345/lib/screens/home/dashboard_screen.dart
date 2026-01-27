import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../utils/role_utils.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/modern_stats_card.dart';
import '../../widgets/role_badge.dart';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> 
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _actionsController;
  late Animation<double> _headerAnimation;
  late Animation<double> _statsAnimation;
  late Animation<Offset> _actionsAnimation;
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _actionsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    ));
    
    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.elasticOut,
    ));
    
    _actionsAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _actionsController,
      curve: Curves.easeOutCubic,
    ));
    
    _refreshData();
    _startAnimations();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _statsController.dispose();
    _actionsController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _statsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _actionsController.forward();
    });
  }

  Future<void> _refreshData() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    await Future.wait([
      walletProvider.refreshBalance(),
      bookingProvider.loadMyBookings(),
    ]);
  }

  Widget _buildModernHeader(dynamic user, String? role) {
    return Container(
      height: 280,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTheme.spacing16,
        left: AppTheme.spacing24,
        right: AppTheme.spacing24,
        bottom: AppTheme.spacing24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with avatar and notifications
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.getRoleGradient(role),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  boxShadow: AppTheme.shadowLG,
                ),
                child: user?.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        child: Image.network(
                          user!.avatarUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
              const Spacer(),
              GlassCard(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                child: Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.neutral700,
                  size: 24,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing24),
          
          // Welcome text
          Text(
            'Chào mừng trở lại,',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            user?.fullName ?? 'Người dùng',
            style: AppTheme.headlineLarge.copyWith(
              color: AppTheme.neutral900,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          // Role badge
          RoleBadge(role: role),
          
          const SizedBox(height: AppTheme.spacing20),
          
          // Weather or time info
          GlassCard(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.8),
                        Colors.amber.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: const Icon(
                    Icons.wb_sunny,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời tiết hôm nay',
                        style: AppTheme.labelMedium.copyWith(
                          color: AppTheme.neutral600,
                        ),
                      ),
                      Text(
                        '28°C - Nắng đẹp',
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Tuyệt vời để chơi pickleball!',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final role = user?.role;
        
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: AnimatedBackground(
            primaryColor: AppTheme.getRoleColor(role),
            secondaryColor: AppTheme.primaryColor,
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Modern Header with Glass Effect
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _headerAnimation,
                      child: _buildModernHeader(user, role),
                    ),
                  ),
                  
                  // Quick Stats with Animation
                  SliverToBoxAdapter(
                    child: ScaleTransition(
                      scale: _statsAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacing16),
                        child: _buildQuickStats(role),
                      ),
                    ),
                  ),
                  
                  // Quick Actions with Slide Animation
                  SliverToBoxAdapter(
                    child: SlideTransition(
                      position: _actionsAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thao tác nhanh',
                              style: AppTheme.headlineMedium.copyWith(
                                color: AppTheme.neutral900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            _buildQuickActions(role),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Recent Activities
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoạt động gần đây',
                            style: AppTheme.headlineMedium.copyWith(
                              color: AppTheme.neutral900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          _buildRecentActivities(),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(String? role) {
    return Consumer3<WalletProvider, BookingProvider, TournamentProvider>(
      builder: (context, walletProvider, bookingProvider, tournamentProvider, child) {
        final stats = <Widget>[];
        
        // Common stats
        stats.addAll([
          ModernStatsCard(
            title: 'Số dư ví',
            value: '${walletProvider.balance.toStringAsFixed(0)}đ',
            icon: Icons.account_balance_wallet,
            color: AppTheme.successColor,
            subtitle: 'Khả dụng',
            trend: '+12%',
            onTap: () {
              // Navigate to wallet
            },
          ),
          ModernStatsCard(
            title: 'Booking',
            value: '${bookingProvider.myBookings.length}',
            icon: Icons.calendar_today,
            color: AppTheme.infoColor,
            subtitle: 'Tháng này',
            trend: '+5',
            onTap: () {
              // Navigate to bookings
            },
          ),
        ]);

        // Role-specific stats
        if (RoleUtils.canManageFinances(role)) {
          stats.addAll([
            ModernStatsCard(
              title: 'Doanh thu',
              value: '50M',
              icon: Icons.trending_up,
              color: AppTheme.treasurerColor,
              subtitle: 'Tháng này',
              trend: '+18%',
              onTap: () {
                // Navigate to financial reports
              },
            ),
            ModernStatsCard(
              title: 'Thành viên',
              value: '248',
              icon: Icons.people,
              color: AppTheme.adminColor,
              subtitle: 'Tổng cộng',
              trend: '+12',
              onTap: () {
                // Navigate to member management
              },
            ),
          ]);
        } else {
          stats.addAll([
            ModernStatsCard(
              title: 'Giải đấu',
              value: '${tournamentProvider.tournaments.length}',
              icon: Icons.emoji_events,
              color: AppTheme.warningColor,
              subtitle: 'Đang diễn ra',
              trend: 'Mới',
              onTap: () {
                // Navigate to tournaments
              },
            ),
            ModernStatsCard(
              title: 'Xếp hạng',
              value: '#15',
              icon: Icons.leaderboard,
              color: AppTheme.primaryColor,
              subtitle: 'Trong CLB',
              trend: '↑3',
              onTap: () {
                // Navigate to leaderboard
              },
            ),
          ]);
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          mainAxisSpacing: AppTheme.spacing16,
          crossAxisSpacing: AppTheme.spacing16,
          children: stats,
        );
      },
    );
  }

  Widget _buildQuickActions(String? role) {
    final actions = <Widget>[];
    
    // Common actions for all users
    actions.addAll([
      _buildActionCard(
        title: 'Đặt sân',
        description: 'Đặt sân pickleball ngay',
        icon: Icons.sports_tennis,
        color: AppTheme.primaryColor,
        onTap: () {
          // Navigate to booking
        },
      ),
      _buildActionCard(
        title: 'Nạp tiền',
        description: 'Nạp tiền vào ví điện tử',
        icon: Icons.add_card,
        color: AppTheme.successColor,
        onTap: () {
          // Navigate to top up
        },
      ),
    ]);

    // Role-specific actions
    if (RoleUtils.isAdmin(role)) {
      actions.addAll([
        _buildActionCard(
          title: 'Quản lý thành viên',
          description: 'Xem và quản lý thành viên',
          icon: Icons.people,
          color: AppTheme.adminColor,
          onTap: () {
            // Navigate to member management
          },
        ),
        _buildActionCard(
          title: 'Quản lý sân',
          description: 'Thêm, sửa, xóa sân',
          icon: Icons.sports_tennis,
          color: AppTheme.adminColor,
          onTap: () {
            // Navigate to court management
          },
        ),
      ]);
    } else if (RoleUtils.isTreasurer(role)) {
      actions.addAll([
        _buildActionCard(
          title: 'Báo cáo tài chính',
          description: 'Xem báo cáo doanh thu',
          icon: Icons.assessment,
          color: AppTheme.treasurerColor,
          onTap: () {
            // Navigate to financial reports
          },
        ),
        _buildActionCard(
          title: 'Xuất Excel',
          description: 'Xuất dữ liệu ra Excel',
          icon: Icons.file_download,
          color: AppTheme.treasurerColor,
          onTap: () {
            // Export to Excel
          },
        ),
      ]);
    } else if (RoleUtils.isReferee(role)) {
      actions.addAll([
        _buildActionCard(
          title: 'Quản lý giải đấu',
          description: 'Tạo và quản lý giải đấu',
          icon: Icons.emoji_events,
          color: AppTheme.refereeColor,
          onTap: () {
            // Navigate to tournament management
          },
        ),
        _buildActionCard(
          title: 'Lịch trọng tài',
          description: 'Xem lịch làm trọng tài',
          icon: Icons.schedule,
          color: AppTheme.refereeColor,
          onTap: () {
            // Navigate to referee schedule
          },
        ),
      ]);
    } else {
      actions.addAll([
        _buildActionCard(
          title: 'Tham gia giải đấu',
          description: 'Đăng ký tham gia giải đấu',
          icon: Icons.emoji_events,
          color: AppTheme.warningColor,
          onTap: () {
            // Navigate to tournaments
          },
        ),
        _buildActionCard(
          title: 'Lịch sử',
          description: 'Xem lịch sử booking',
          icon: Icons.history,
          color: AppTheme.infoColor,
          onTap: () {
            // Navigate to booking history
          },
        ),
      ]);
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      mainAxisSpacing: AppTheme.spacing16,
      crossAxisSpacing: AppTheme.spacing16,
      children: actions,
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SimpleCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: AppTheme.shadowSM,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              title,
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              description,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutral600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                'Hoạt động gần đây',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // View all activities
                },
                child: Text(
                  'Xem tất cả',
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildActivityItem(
            icon: Icons.sports_tennis,
            title: 'Đặt sân thành công',
            subtitle: 'Sân A - 14:00 - 16:00',
            time: '2 giờ trước',
            gradient: LinearGradient(
              colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.7)],
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildActivityItem(
            icon: Icons.account_balance_wallet,
            title: 'Nạp tiền vào ví',
            subtitle: '+500.000đ',
            time: '1 ngày trước',
            gradient: LinearGradient(
              colors: [AppTheme.infoColor, AppTheme.infoColor.withOpacity(0.7)],
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildActivityItem(
            icon: Icons.emoji_events,
            title: 'Tham gia giải đấu',
            subtitle: 'Giải đấu mùa xuân 2024',
            time: '3 ngày trước',
            gradient: LinearGradient(
              colors: [AppTheme.warningColor, AppTheme.warningColor.withOpacity(0.7)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: AppTheme.neutral200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              boxShadow: AppTheme.shadowSM,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral900,
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
                time,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.neutral500,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}