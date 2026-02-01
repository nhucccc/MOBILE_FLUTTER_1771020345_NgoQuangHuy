import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';
import '../../widgets/modern_stats_card.dart';

class EnhancedAdminDashboardScreen extends StatefulWidget {
  const EnhancedAdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedAdminDashboardScreen> createState() => _EnhancedAdminDashboardScreenState();
}

class _EnhancedAdminDashboardScreenState extends State<EnhancedAdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get('/admin/dashboard-stats');
      print('Admin dashboard API response: $response'); // Debug log
      
      if (response is Map<String, dynamic>) {
        if (response['success'] == true && response['data'] != null) {
          setState(() {
            _stats = response['data'];
            _isLoading = false;
          });
        } else {
          // Try to use response directly if it contains stats
          setState(() {
            _stats = response;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Định dạng dữ liệu không hợp lệ';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Admin dashboard error: $e'); // Debug log
      setState(() {
        _error = 'Lỗi kết nối: $e';
        _isLoading = false;
        // Use fallback mock data
        _stats = {
          'totalMembers': 156,
          'totalBookings': 1234,
          'totalRevenue': 45600000,
          'activeTournaments': 3,
          'pendingDeposits': 8,
          'systemHealth': 'Good',
          'todayBookings': 23,
          'monthlyRevenue': 12500000,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Trị Admin'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Card
                        SimpleCard(
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings,
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
                                      'Chào mừng, Admin!',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quản lý hệ thống Pickleball Club với AI',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Statistics Cards
                        const Text(
                          'Thống kê realtime',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                          children: [
                            ModernStatsCard(
                              title: 'Thành viên',
                              value: '${_stats['totalMembers'] ?? 0}',
                              subtitle: 'Tổng số thành viên',
                              icon: Icons.people,
                              color: Colors.blue,
                              trend: '+${_stats['newMembersThisMonth'] ?? 0} tháng này',
                              isPositiveTrend: true,
                            ),
                            ModernStatsCard(
                              title: 'Đặt sân hôm nay',
                              value: '${_stats['todayBookings'] ?? 0}',
                              subtitle: 'Lượt đặt sân',
                              icon: Icons.sports_tennis,
                              color: Colors.green,
                              trend: 'Hôm nay',
                              isPositiveTrend: true,
                            ),
                            ModernStatsCard(
                              title: 'Doanh thu tháng',
                              value: '${(_stats['monthlyRevenue'] ?? 0).toStringAsFixed(0)}đ',
                              subtitle: 'Tháng này',
                              icon: Icons.attach_money,
                              color: Colors.orange,
                              trend: '+${(_stats['revenueGrowth'] ?? 0).toStringAsFixed(1)}%',
                              isPositiveTrend: (_stats['revenueGrowth'] ?? 0) >= 0,
                            ),
                            ModernStatsCard(
                              title: 'Nạp tiền chờ duyệt',
                              value: '${_stats['pendingDeposits'] ?? 0}',
                              subtitle: 'Cần xử lý',
                              icon: Icons.pending_actions,
                              color: Colors.red,
                              badge: _stats['pendingDeposits'] > 0 ? 'Mới' : null,
                              description: 'Yêu cầu nạp tiền',
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Quick Actions
                        const Text(
                          'Thao tác nhanh',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                          children: [
                            _buildActionCard(
                              'Duyệt nạp tiền',
                              'Xử lý yêu cầu nạp tiền',
                              Icons.approval,
                              Colors.green,
                              () => Navigator.pushNamed(context, '/admin/deposit-approval'),
                              badge: _stats['pendingDeposits'] > 0 ? '${_stats['pendingDeposits']}' : null,
                            ),
                            _buildActionCard(
                              'Quản lý sân',
                              'Cài đặt sân và giá',
                              Icons.sports_tennis,
                              Colors.blue,
                              () => Navigator.pushNamed(context, '/admin/court-management'),
                            ),
                            _buildActionCard(
                              'Quản lý thành viên',
                              'Xem và chỉnh sửa thành viên',
                              Icons.people_alt,
                              Colors.purple,
                              () => Navigator.pushNamed(context, '/admin/member-management'),
                            ),
                            _buildActionCard(
                              'Báo cáo hệ thống',
                              'Xem báo cáo chi tiết',
                              Icons.analytics,
                              Colors.orange,
                              () => Navigator.pushNamed(context, '/admin/reports'),
                            ),
                            _buildActionCard(
                              'Cài đặt hệ thống',
                              'Cấu hình ứng dụng',
                              Icons.settings,
                              Colors.grey,
                              () => Navigator.pushNamed(context, '/admin/system-settings'),
                            ),
                            _buildActionCard(
                              'Quản lý giải đấu',
                              'Tạo và quản lý giải đấu',
                              Icons.emoji_events,
                              Colors.amber,
                              () => Navigator.pushNamed(context, '/admin/tournament-management'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // System Health
                        const Text(
                          'Tình trạng hệ thống',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        SimpleCard(
                          child: Column(
                            children: [
                              _buildSystemHealthItem(
                                Icons.cloud_done,
                                'API Server',
                                'Hoạt động bình thường',
                                Colors.green,
                                '99.9% uptime',
                              ),
                              const Divider(),
                              _buildSystemHealthItem(
                                Icons.storage,
                                'Database',
                                'Kết nối ổn định',
                                Colors.green,
                                '${_stats['dbConnections'] ?? 0} connections',
                              ),
                              const Divider(),
                              _buildSystemHealthItem(
                                Icons.wifi,
                                'SignalR Hub',
                                'Realtime hoạt động',
                                Colors.green,
                                '${_stats['activeConnections'] ?? 0} users online',
                              ),
                              const Divider(),
                              _buildSystemHealthItem(
                                Icons.memory,
                                'Slot Reservation',
                                'Cache hoạt động',
                                Colors.green,
                                '${_stats['activeSlots'] ?? 0} slots reserved',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Recent Activities
                        const Text(
                          'Hoạt động gần đây',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        SimpleCard(
                          child: Column(
                            children: [
                              _buildActivityItem(
                                Icons.person_add,
                                'Thành viên mới đăng ký',
                                '${_stats['recentNewMembers'] ?? 0} thành viên mới hôm nay',
                                Colors.blue,
                              ),
                              const Divider(),
                              _buildActivityItem(
                                Icons.sports_tennis,
                                'Đặt sân mới',
                                '${_stats['recentBookings'] ?? 0} lượt đặt sân trong 24h qua',
                                Colors.green,
                              ),
                              const Divider(),
                              _buildActivityItem(
                                Icons.attach_money,
                                'Giao dịch ví',
                                '${_stats['recentTransactions'] ?? 0} giao dịch mới',
                                Colors.orange,
                              ),
                              if ((_stats['pendingDeposits'] ?? 0) > 0) ...[
                                const Divider(),
                                _buildActivityItem(
                                  Icons.pending_actions,
                                  'Yêu cầu nạp tiền',
                                  '${_stats['pendingDeposits']} yêu cầu chờ duyệt',
                                  Colors.red,
                                  onTap: () => Navigator.pushNamed(context, '/admin/deposit-approval'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? badge,
  }) {
    return SimpleCard(
      onTap: onTap,
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthItem(
    IconData icon,
    String title,
    String status,
    Color color,
    String detail,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}