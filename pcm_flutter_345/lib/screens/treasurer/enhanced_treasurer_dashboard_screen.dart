import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';
import '../../widgets/modern_stats_card.dart';

class EnhancedTreasurerDashboardScreen extends StatefulWidget {
  const EnhancedTreasurerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedTreasurerDashboardScreen> createState() => _EnhancedTreasurerDashboardScreenState();
}

class _EnhancedTreasurerDashboardScreenState extends State<EnhancedTreasurerDashboardScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic> _stats = {};
  List<dynamic> _pendingDeposits = [];
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
      final statsResponse = await _apiService.get('/api/admin/dashboard-stats');
      final depositsResponse = await _apiService.get('/api/admin/pending-deposits');
      
      if (statsResponse['success'] && depositsResponse['success']) {
        setState(() {
          _stats = statsResponse['data'];
          _pendingDeposits = depositsResponse['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Không thể tải dữ liệu';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _processDeposit(int transactionId, bool isApproved) async {
    try {
      final response = await _apiService.post('/api/admin/process-deposit', {
        'transactionId': transactionId,
        'isApproved': isApproved,
        'adminNote': isApproved ? 'Đã duyệt bởi Treasurer' : 'Từ chối bởi Treasurer',
      });

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved ? '✅ Đã duyệt nạp tiền' : '❌ Đã từ chối nạp tiền'),
            backgroundColor: isApproved ? Colors.green : Colors.red,
          ),
        );
        
        // Reload data
        await _loadDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${response['message'] ?? 'Có lỗi xảy ra'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thủ Quỹ'),
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
                                  gradient: LinearGradient(
                                    colors: [Colors.green.shade400, Colors.green.shade600],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
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
                                      'Chào mừng, Kế Toán!',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quản lý tài chính và giao dịch với AI',
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

                        // Financial Statistics
                        const Text(
                          'Thống kê tài chính realtime',
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
                              title: 'Doanh thu tháng',
                              value: '${(_stats['monthlyRevenue'] ?? 0).toStringAsFixed(0)}đ',
                              subtitle: 'Tháng này',
                              icon: Icons.trending_up,
                              color: Colors.green,
                              trend: '+${(_stats['revenueGrowth'] ?? 0).toStringAsFixed(1)}%',
                              isPositiveTrend: (_stats['revenueGrowth'] ?? 0) >= 0,
                            ),
                            ModernStatsCard(
                              title: 'Nạp tiền chờ duyệt',
                              value: '${_stats['pendingDeposits'] ?? 0}',
                              subtitle: 'Yêu cầu',
                              icon: Icons.pending_actions,
                              color: Colors.orange,
                              badge: _stats['pendingDeposits'] > 0 ? 'Mới' : null,
                              description: 'Cần xử lý ngay',
                            ),
                            ModernStatsCard(
                              title: 'Tổng giao dịch',
                              value: '${_stats['totalTransactions'] ?? 0}',
                              subtitle: 'Hôm nay',
                              icon: Icons.receipt_long,
                              color: Colors.blue,
                              trend: 'Hôm nay',
                              isPositiveTrend: true,
                            ),
                            ModernStatsCard(
                              title: 'Số dư hệ thống',
                              value: '${(_stats['systemBalance'] ?? 0).toStringAsFixed(0)}đ',
                              subtitle: 'Tổng ví thành viên',
                              icon: Icons.account_balance_wallet,
                              color: Colors.purple,
                              trend: 'Tổng cộng',
                              isPositiveTrend: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Pending Deposits Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Yêu cầu nạp tiền chờ duyệt',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_pendingDeposits.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_pendingDeposits.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (_pendingDeposits.isEmpty)
                          SimpleCard(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: Colors.green.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Không có yêu cầu nạp tiền nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tất cả yêu cầu đã được xử lý',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._pendingDeposits.map((deposit) => _buildDepositCard(deposit)).toList(),

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
                              'Báo cáo tài chính',
                              'Xem báo cáo chi tiết',
                              Icons.analytics,
                              Colors.blue,
                              () => Navigator.pushNamed(context, '/treasurer/financial-reports'),
                            ),
                            _buildActionCard(
                              'Lịch sử giao dịch',
                              'Xem tất cả giao dịch',
                              Icons.history,
                              Colors.green,
                              () => Navigator.pushNamed(context, '/treasurer/transaction-history'),
                            ),
                            _buildActionCard(
                              'Quản lý ví',
                              'Xem ví thành viên',
                              Icons.account_balance_wallet,
                              Colors.purple,
                              () => Navigator.pushNamed(context, '/treasurer/wallet-management'),
                            ),
                            _buildActionCard(
                              'Cài đặt thanh toán',
                              'Cấu hình payment',
                              Icons.payment,
                              Colors.orange,
                              () => Navigator.pushNamed(context, '/treasurer/payment-settings'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDepositCard(Map<String, dynamic> deposit) {
    return SimpleCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deposit['memberName'] ?? 'Không rõ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Số tiền: ${(deposit['amount'] ?? 0).toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Thời gian: ${deposit['createdDate'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (deposit['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Ghi chú: ${deposit['description']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _processDeposit(deposit['id'], false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _processDeposit(deposit['id'], true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Duyệt', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SimpleCard(
      onTap: onTap,
      child: Column(
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
    );
  }
}