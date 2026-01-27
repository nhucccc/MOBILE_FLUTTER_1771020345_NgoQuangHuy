import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/role_badge.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AnimatedBackground(
        primaryColor: AppTheme.infoColor,
        secondaryColor: AppTheme.primaryColor,
        child: SafeArea(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              
              return CustomScrollView(
                slivers: [
                  // Profile Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing24),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: AppTheme.getRoleGradient(user?.role),
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: AppTheme.shadowLG,
                            ),
                            child: user?.avatarUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.network(
                                      user!.avatarUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacing20),
                          
                          // Name
                          Text(
                            user?.fullName ?? 'Người dùng',
                            style: AppTheme.headlineLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neutral900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: AppTheme.spacing8),
                          
                          // Email
                          if (user?.email != null)
                            Text(
                              user!.email!,
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.neutral600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          
                          const SizedBox(height: AppTheme.spacing16),
                          
                          // Role Badge
                          RoleBadge(role: user?.role),
                          
                          const SizedBox(height: AppTheme.spacing12),
                          
                          // Tier Badge
                          if (user?.member != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: _getTierGradient(user!.member!.tier),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: AppTheme.shadowSM,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getTierIcon(user.member!.tier),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Hạng ${user.member!.tierDisplayName}',
                                    style: AppTheme.labelMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Profile Info
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin cá nhân',
                              style: AppTheme.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing20),
                            
                            _buildInfoItem(
                              icon: Icons.person_outline,
                              title: 'Họ và tên',
                              value: user?.fullName ?? 'Chưa cập nhật',
                            ),
                            
                            _buildInfoItem(
                              icon: Icons.email_outlined,
                              title: 'Email',
                              value: user?.email ?? 'Chưa cập nhật',
                            ),
                            
                            _buildInfoItem(
                              icon: Icons.phone_outlined,
                              title: 'Số điện thoại',
                              value: user?.phoneNumber ?? 'Chưa cập nhật',
                            ),
                            
                            _buildInfoItem(
                              icon: Icons.badge_outlined,
                              title: 'Vai trò',
                              value: user?.role ?? 'Member',
                            ),
                            
                            if (user?.member != null) ...[
                              _buildInfoItem(
                                icon: Icons.military_tech,
                                title: 'Hạng thành viên',
                                value: user!.member!.tierDisplayName,
                              ),
                              
                              _buildInfoItem(
                                icon: Icons.account_balance_wallet,
                                title: 'Số dư ví',
                                value: '${user.member!.walletBalance.toStringAsFixed(0)}đ',
                              ),
                              
                              _buildInfoItem(
                                icon: Icons.calendar_today_outlined,
                                title: 'Ngày tham gia',
                                value: user.member!.joinDate != null
                                    ? '${user.member!.joinDate!.day}/${user.member!.joinDate!.month}/${user.member!.joinDate!.year}'
                                    : 'Chưa cập nhật',
                              ),
                              
                              _buildInfoItem(
                                icon: Icons.verified_outlined,
                                title: 'Trạng thái',
                                value: user.member!.isActive ? 'Hoạt động' : 'Không hoạt động',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacing24,
                        AppTheme.spacing24,
                        AppTheme.spacing24,
                        kBottomNavigationBarHeight + AppTheme.spacing32, // Thêm padding bottom cho bottom nav
                      ),
                      child: Column(
                        children: [
                          _buildActionCard(
                            icon: Icons.edit_outlined,
                            title: 'Chỉnh sửa thông tin',
                            subtitle: 'Cập nhật thông tin cá nhân',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: AppTheme.spacing16),
                          
                          _buildActionCard(
                            icon: Icons.security_outlined,
                            title: 'Đổi mật khẩu',
                            subtitle: 'Thay đổi mật khẩu đăng nhập',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChangePasswordScreen(),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: AppTheme.spacing16),
                          
                          _buildActionCard(
                            icon: Icons.notifications_outlined,
                            title: 'Cài đặt thông báo',
                            subtitle: 'Quản lý thông báo ứng dụng',
                            onTap: () {
                              // Navigate to notification settings
                            },
                          ),
                          
                          const SizedBox(height: AppTheme.spacing16),
                          
                          _buildActionCard(
                            icon: Icons.help_outline,
                            title: 'Trợ giúp & Hỗ trợ',
                            subtitle: 'Câu hỏi thường gặp và liên hệ',
                            onTap: () {
                              // Navigate to help
                            },
                          ),
                          
                          const SizedBox(height: AppTheme.spacing32),
                          
                          // Logout button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showLogoutDialog(context, authProvider),
                              icon: const Icon(Icons.logout),
                              label: const Text('Đăng xuất'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                              ),
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

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.neutral600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  value,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
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
          Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.neutral400,
            size: 16,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppTheme.errorColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              Text(
                'Đăng xuất',
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop(); // Close dialog first
                        print('Logout button pressed'); // Debug log
                        await authProvider.logout();
                        print('Logout completed, navigating to login'); // Debug log
                        
                        // Force navigate to login screen
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Đăng xuất'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getTierGradient(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return LinearGradient(
          colors: [Colors.brown.shade400, Colors.brown.shade600],
        );
      case 'silver':
        return LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade600],
        );
      case 'gold':
        return LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade600],
        );
      case 'diamond':
        return LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade600],
        );
      default:
        return LinearGradient(
          colors: [AppTheme.neutral400, AppTheme.neutral600],
        );
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return Icons.workspace_premium;
      case 'silver':
        return Icons.military_tech;
      case 'gold':
        return Icons.emoji_events;
      case 'diamond':
        return Icons.diamond;
      default:
        return Icons.star;
    }
  }
}