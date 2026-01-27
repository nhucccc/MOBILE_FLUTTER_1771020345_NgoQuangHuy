import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/role_badge.dart';

class RefereeDashboardScreen extends StatefulWidget {
  const RefereeDashboardScreen({super.key});

  @override
  State<RefereeDashboardScreen> createState() => _RefereeDashboardScreenState();
}

class _RefereeDashboardScreenState extends State<RefereeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: CustomScrollView(
            slivers: [
              // Referee Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.refereeGradient,
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
                                Icons.sports,
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
                                    'Bảng điều khiển Trọng tài',
                                    style: AppTheme.headingMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Quản lý giải đấu và trọng tài',
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
              
              // Tournament Overview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng quan giải đấu',
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
                            title: 'Giải đấu đang diễn ra',
                            value: '3',
                            icon: Icons.emoji_events,
                            color: AppTheme.refereeColor,
                            subtitle: '45 thành viên tham gia',
                            onTap: () => _navigateToActiveTournaments(),
                          ),
                          StatsCard(
                            title: 'Trận đấu hôm nay',
                            value: '8',
                            icon: Icons.sports_tennis,
                            color: AppTheme.successColor,
                            subtitle: '5 trận đã hoàn thành',
                            onTap: () => _navigateToTodayMatches(),
                          ),
                          StatsCard(
                            title: 'Lịch trọng tài',
                            value: '12',
                            icon: Icons.schedule,
                            color: AppTheme.infoColor,
                            subtitle: 'Tuần này',
                            onTap: () => _navigateToRefereeSchedule(),
                          ),
                          StatsCard(
                            title: 'Đánh giá trọng tài',
                            value: '4.8/5',
                            icon: Icons.star,
                            color: AppTheme.warningColor,
                            subtitle: 'Từ 156 đánh giá',
                            onTap: () => _navigateToRefereeRatings(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Referee Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quản lý trọng tài',
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
                            title: 'Tạo giải đấu',
                            description: 'Tạo giải đấu mới',
                            icon: Icons.add_circle,
                            color: AppTheme.refereeColor,
                            onTap: () => _navigateToCreateTournament(),
                          ),
                          ActionCard(
                            title: 'Quản lý giải đấu',
                            description: 'Chỉnh sửa giải đấu',
                            icon: Icons.edit,
                            color: AppTheme.refereeColor,
                            onTap: () => _navigateToManageTournaments(),
                          ),
                          ActionCard(
                            title: 'Lập lịch trận đấu',
                            description: 'Sắp xếp lịch thi đấu',
                            icon: Icons.calendar_today,
                            color: AppTheme.refereeColor,
                            onTap: () => _navigateToScheduleMatches(),
                          ),
                          ActionCard(
                            title: 'Nhập kết quả',
                            description: 'Cập nhật tỷ số',
                            icon: Icons.scoreboard,
                            color: AppTheme.refereeColor,
                            onTap: () => _navigateToEnterResults(),
                          ),
                          ActionCard(
                            title: 'Bảng xếp hạng',
                            description: 'Xem ranking',
                            icon: Icons.leaderboard,
                            color: AppTheme.refereeColor,
                            onTap: () => _navigateToLeaderboard(),
                          ),
                          ActionCard(
                            title: 'Báo cáo giải đấu',
                            description: 'Thống kê chi tiết',
                            icon: Icons.assessment,
                            color: AppTheme.refereeColor,
                            onTap: () => _navigateToTournamentReports(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Upcoming Matches
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trận đấu sắp tới',
                        style: AppTheme.headingMedium,
                      ),
                      const SizedBox(height: 16),
                      CustomCard(
                        child: Column(
                          children: [
                            _buildMatchItem(
                              player1: 'Nguyễn Văn A',
                              player2: 'Trần Thị B',
                              time: '14:00 - Hôm nay',
                              court: 'Sân A',
                              tournament: 'Giải đấu mùa xuân',
                              status: 'Sắp diễn ra',
                              statusColor: AppTheme.warningColor,
                            ),
                            const Divider(),
                            _buildMatchItem(
                              player1: 'Lê Văn C',
                              player2: 'Phạm Thị D',
                              time: '16:00 - Hôm nay',
                              court: 'Sân B',
                              tournament: 'Giải đấu mùa xuân',
                              status: 'Chờ xác nhận',
                              statusColor: AppTheme.infoColor,
                            ),
                            const Divider(),
                            _buildMatchItem(
                              player1: 'Hoàng Văn E',
                              player2: 'Vũ Thị F',
                              time: '09:00 - Ngày mai',
                              court: 'Sân C',
                              tournament: 'Giải đấu hè',
                              status: 'Đã lên lịch',
                              statusColor: AppTheme.successColor,
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

  Widget _buildMatchItem({
    required String player1,
    required String player2,
    required String time,
    required String court,
    required String tournament,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.sports_tennis,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$player1 vs $player2',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tournament,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.refereeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$time • $court',
                  style: AppTheme.bodySmall,
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
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToActiveTournaments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Giải đấu đang diễn ra')),
    );
  }

  void _navigateToTodayMatches() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trận đấu hôm nay')),
    );
  }

  void _navigateToRefereeSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lịch trọng tài')),
    );
  }

  void _navigateToRefereeRatings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đánh giá trọng tài')),
    );
  }

  void _navigateToCreateTournament() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tạo giải đấu mới')),
    );
  }

  void _navigateToManageTournaments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quản lý giải đấu')),
    );
  }

  void _navigateToScheduleMatches() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lập lịch trận đấu')),
    );
  }

  void _navigateToEnterResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nhập kết quả trận đấu')),
    );
  }

  void _navigateToLeaderboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bảng xếp hạng')),
    );
  }

  void _navigateToTournamentReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Báo cáo giải đấu')),
    );
  }
}