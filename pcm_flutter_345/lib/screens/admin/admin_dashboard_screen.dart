import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/modern_stats_card.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/role_badge.dart';
import 'enhanced_member_management_screen.dart';
import 'deposit_approval_screen.dart';
import 'debug_court_screen.dart';
import 'system_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: AnimatedBackground(
            primaryColor: AppTheme.adminColor,
            secondaryColor: AppTheme.primaryColor,
            child: CustomScrollView(
              slivers: [
                // Modern Admin Header
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _headerAnimationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _headerFadeAnimation,
                        child: SlideTransition(
                          position: _headerSlideAnimation,
                          child: Container(
                            margin: const EdgeInsets.all(AppTheme.spacing16),
                            child: GlassCard(
                              padding: const EdgeInsets.all(AppTheme.spacing24),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.adminGradient,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                                ),
                                padding: const EdgeInsets.all(AppTheme.spacing24),
                                child: SafeArea(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(AppTheme.spacing16),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.admin_panel_settings_rounded,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(width: AppTheme.spacing20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Bảng điều khiển Admin',
                                                  style: AppTheme.headlineMedium.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: AppTheme.spacing4),
                                                Text(
                                                  'Quản lý toàn bộ hệ thống CLB Pickleball',
                                                  style: AppTheme.bodyMedium.copyWith(
                                                    color: Colors.white.withOpacity(0.8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppTheme.spacing24),
                                      Row(
                                        children: [
                                          RoleBadge(
                                            role: user?.role,
                                            showDescription: false,
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppTheme.spacing12,
                                              vertical: AppTheme.spacing8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  color: Colors.white.withOpacity(0.8),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: AppTheme.spacing4),
                                                Text(
                                                  'Hôm nay',
                                                  style: AppTheme.labelMedium.copyWith(
                                                    color: Colors.white.withOpacity(0.8),
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
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // System Overview Stats
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng quan hệ thống',
                          style: AppTheme.headlineMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 2.2, // Tăng từ 1.8 lên 2.2 để làm thấp hơn
                          mainAxisSpacing: AppTheme.spacing8,
                          crossAxisSpacing: AppTheme.spacing8,
                          children: [
                            ModernStatsCard(
                              title: 'Tổng thành viên',
                              value: '234',
                              icon: Icons.people_rounded,
                              color: AppTheme.adminColor,
                              subtitle: 'Hoạt động',
                              trend: '+12',
                              isPositiveTrend: true,
                              onTap: () => _navigateToMemberManagement(),
                            ),
                            ModernStatsCard(
                              title: 'Doanh thu tháng',
                              value: '125M',
                              icon: Icons.trending_up_rounded,
                              color: AppTheme.successColor,
                              subtitle: 'VNĐ',
                              trend: '+15%',
                              isPositiveTrend: true,
                              onTap: () => _navigateToFinancialReports(),
                            ),
                            ModernStatsCard(
                              title: 'Booking hôm nay',
                              value: '45',
                              icon: Icons.calendar_today_rounded,
                              color: AppTheme.infoColor,
                              subtitle: 'Lượt đặt',
                              trend: '+8',
                              isPositiveTrend: true,
                              onTap: () => _navigateToBookingManagement(),
                            ),
                            ModernStatsCard(
                              title: 'Sân hoạt động',
                              value: '8/10',
                              icon: Icons.sports_tennis_rounded,
                              color: AppTheme.warningColor,
                              subtitle: 'Sân',
                              trend: '2 bảo trì',
                              isPositiveTrend: false,
                              onTap: () => _navigateToCourtManagement(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacing32)),
                
                // Quick Admin Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quản lý nhanh',
                          style: AppTheme.headlineMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 2.4, // Tăng từ 1.8 lên 2.4 để làm thấp hơn nữa
                          mainAxisSpacing: AppTheme.spacing8,
                          crossAxisSpacing: AppTheme.spacing8,
                          children: [
                            ModernActionCard(
                              title: 'QL TV',
                              description: 'Quản lý thành viên',
                              icon: Icons.people_alt_rounded,
                              color: AppTheme.adminColor,
                              onTap: () => _navigateToMemberManagement(),
                            ),
                            ModernActionCard(
                              title: 'Duyệt nạp',
                              description: 'Duyệt yêu cầu',
                              icon: Icons.approval_rounded,
                              color: AppTheme.successColor,
                              badge: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacing8,
                                  vertical: AppTheme.spacing4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                ),
                                child: Text(
                                  '3',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: () => _navigateToDepositApproval(),
                            ),
                            ModernActionCard(
                              title: 'QL Sân',
                              description: 'Quản lý sân',
                              icon: Icons.sports_tennis_rounded,
                              color: AppTheme.infoColor,
                              onTap: () => _navigateToCourtManagement(),
                            ),
                            ModernActionCard(
                              title: 'Cài đặt',
                              description: 'Cấu hình',
                              icon: Icons.settings_rounded,
                              color: AppTheme.treasurerColor,
                              onTap: () => _navigateToSystemSettings(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacing32)),
                
                // Recent Admin Activities
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hoạt động gần đây',
                          style: AppTheme.headlineMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        GlassCard(
                          child: Column(
                            children: [
                              _buildModernActivityItem(
                                icon: Icons.person_add_rounded,
                                title: 'Thêm thành viên mới',
                                subtitle: 'Nguyễn Văn A đã được thêm vào hệ thống',
                                time: '10 phút trước',
                                color: AppTheme.successColor,
                              ),
                              const Divider(height: 1),
                              _buildModernActivityItem(
                                icon: Icons.sports_tennis_rounded,
                                title: 'Cập nhật giá sân',
                                subtitle: 'Sân A: 150.000đ/giờ → 160.000đ/giờ',
                                time: '2 giờ trước',
                                color: AppTheme.warningColor,
                              ),
                              const Divider(height: 1),
                              _buildModernActivityItem(
                                icon: Icons.security_rounded,
                                title: 'Backup dữ liệu',
                                subtitle: 'Backup tự động đã hoàn thành',
                                time: '1 ngày trước',
                                color: AppTheme.infoColor,
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
          ),
        );
      },
    );
  }

  Widget _buildModernActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
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
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
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
                  style: AppTheme.titleMedium.copyWith(
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
          const SizedBox(width: AppTheme.spacing8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing8,
              vertical: AppTheme.spacing4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Text(
              time,
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.neutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToMemberManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EnhancedMemberManagementScreen()),
    );
  }

  void _navigateToCourtManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DebugCourtScreen()),
    );
  }

  void _navigateToDepositApproval() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DepositApprovalScreen()),
    );
  }

  void _navigateToSystemSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SystemSettingsScreen()),
    );
  }

  void _navigateToFinancialReports() {
    // TODO: Navigate to financial reports screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng báo cáo tài chính')),
    );
  }

  void _navigateToBookingManagement() {
    // TODO: Navigate to booking management screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng quản lý booking')),
    );
  }

  void _navigateToSystemReports() {
    // TODO: Navigate to system reports screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng báo cáo hệ thống')),
    );
  }

  void _navigateToPaymentSettings() {
    // TODO: Navigate to payment settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng cài đặt thanh toán')),
    );
  }

  void _navigateToBackupRestore() {
    // TODO: Navigate to backup restore screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng backup & restore')),
    );
  }
}