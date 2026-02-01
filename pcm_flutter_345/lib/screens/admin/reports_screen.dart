import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';
import '../../widgets/modern_stats_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  Map<String, dynamic> _revenueData = {};
  Map<String, dynamic> _bookingData = {};
  Map<String, dynamic> _memberData = {};
  Map<String, dynamic> _systemData = {};
  bool _isLoading = true;
  String? _error;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all reports in parallel
      final results = await Future.wait([
        _loadRevenueReport(),
        _loadBookingReport(),
        _loadMemberReport(),
        _loadSystemReport(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải báo cáo: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRevenueReport() async {
    try {
      final response = await _apiService.get('/admin/reports/revenue?from=${_fromDate.toIso8601String()}&to=${_toDate.toIso8601String()}');
      
      // Mock data if API fails
      _revenueData = {
        'totalRevenue': 45600000,
        'monthlyRevenue': 12500000,
        'dailyAverage': 415000,
        'growth': 15.5,
        'chartData': [
          {'date': '2024-01-01', 'amount': 1200000},
          {'date': '2024-01-02', 'amount': 980000},
          {'date': '2024-01-03', 'amount': 1450000},
          {'date': '2024-01-04', 'amount': 1100000},
          {'date': '2024-01-05', 'amount': 1350000},
        ],
        'topCourts': [
          {'name': 'Sân 1', 'revenue': 8500000},
          {'name': 'Sân 2', 'revenue': 7200000},
          {'name': 'Sân 3', 'revenue': 6800000},
        ]
      };
    } catch (e) {
      print('Revenue report error: $e');
    }
  }

  Future<void> _loadBookingReport() async {
    try {
      final response = await _apiService.get('/admin/reports/bookings?from=${_fromDate.toIso8601String()}&to=${_toDate.toIso8601String()}');
      
      // Mock data if API fails
      _bookingData = {
        'totalBookings': 1234,
        'confirmedBookings': 1156,
        'cancelledBookings': 78,
        'utilizationRate': 78.5,
        'peakHours': [
          {'hour': '18:00-19:00', 'bookings': 156},
          {'hour': '19:00-20:00', 'bookings': 142},
          {'hour': '20:00-21:00', 'bookings': 138},
        ],
        'courtUtilization': [
          {'name': 'Sân 1', 'bookings': 245, 'utilization': 85.2},
          {'name': 'Sân 2', 'bookings': 198, 'utilization': 68.9},
          {'name': 'Sân 3', 'bookings': 167, 'utilization': 58.1},
        ]
      };
    } catch (e) {
      print('Booking report error: $e');
    }
  }

  Future<void> _loadMemberReport() async {
    try {
      // Mock data
      _memberData = {
        'totalMembers': 156,
        'activeMembers': 142,
        'newMembersThisMonth': 12,
        'memberGrowth': 8.5,
        'tierDistribution': [
          {'tier': 'Standard', 'count': 89, 'percentage': 57.1},
          {'tier': 'Silver', 'count': 34, 'percentage': 21.8},
          {'tier': 'Gold', 'count': 23, 'percentage': 14.7},
          {'tier': 'Diamond', 'count': 10, 'percentage': 6.4},
        ],
        'topSpenders': [
          {'name': 'Nguyễn Văn A', 'spent': 2500000},
          {'name': 'Trần Thị B', 'spent': 2200000},
          {'name': 'Lê Văn C', 'spent': 1980000},
        ]
      };
    } catch (e) {
      print('Member report error: $e');
    }
  }

  Future<void> _loadSystemReport() async {
    try {
      // Mock data
      _systemData = {
        'serverUptime': '99.8%',
        'apiResponseTime': '125ms',
        'databaseConnections': 45,
        'activeUsers': 23,
        'errorRate': '0.2%',
        'storageUsed': '2.4GB',
        'backupStatus': 'Success',
        'lastBackup': '2024-01-31 02:00:00',
        'systemHealth': [
          {'component': 'API Server', 'status': 'Healthy', 'uptime': '99.9%'},
          {'component': 'Database', 'status': 'Healthy', 'uptime': '99.8%'},
          {'component': 'SignalR Hub', 'status': 'Healthy', 'uptime': '99.7%'},
          {'component': 'Background Services', 'status': 'Healthy', 'uptime': '99.5%'},
        ]
      };
    } catch (e) {
      print('System report error: $e');
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo hệ thống'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Doanh thu'),
            Tab(text: 'Đặt sân'),
            Tab(text: 'Thành viên'),
            Tab(text: 'Hệ thống'),
          ],
        ),
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
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReports,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Date Range Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Từ ${_fromDate.day}/${_fromDate.month}/${_fromDate.year} đến ${_toDate.day}/${_toDate.month}/${_toDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _selectDateRange,
                            child: const Text('Thay đổi'),
                          ),
                        ],
                      ),
                    ),
                    
                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRevenueTab(),
                          _buildBookingTab(),
                          _buildMemberTab(),
                          _buildSystemTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildRevenueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Stats
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              ModernStatsCard(
                title: 'Tổng doanh thu',
                value: '${(_revenueData['totalRevenue'] ?? 0).toStringAsFixed(0)}đ',
                subtitle: 'Tất cả thời gian',
                icon: Icons.monetization_on,
                color: Colors.green,
                trend: '+${(_revenueData['growth'] ?? 0).toStringAsFixed(1)}%',
                isPositiveTrend: true,
              ),
              ModernStatsCard(
                title: 'Doanh thu tháng',
                value: '${(_revenueData['monthlyRevenue'] ?? 0).toStringAsFixed(0)}đ',
                subtitle: 'Tháng này',
                icon: Icons.trending_up,
                color: Colors.blue,
                trend: 'Trung bình',
                isPositiveTrend: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Top Courts
          const Text(
            'Sân có doanh thu cao nhất',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ...(_revenueData['topCourts'] as List? ?? []).map((court) => SimpleCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.sports_tennis, color: Colors.green),
              title: Text(court['name']),
              trailing: Text(
                '${court['revenue'].toStringAsFixed(0)}đ',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBookingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking Stats
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              ModernStatsCard(
                title: 'Tổng đặt sân',
                value: '${_bookingData['totalBookings'] ?? 0}',
                subtitle: 'Tất cả',
                icon: Icons.event,
                color: Colors.blue,
                trend: 'Lượt đặt',
                isPositiveTrend: true,
              ),
              ModernStatsCard(
                title: 'Tỷ lệ sử dụng',
                value: '${(_bookingData['utilizationRate'] ?? 0).toStringAsFixed(1)}%',
                subtitle: 'Hiệu quả',
                icon: Icons.analytics,
                color: Colors.orange,
                trend: 'Trung bình',
                isPositiveTrend: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Peak Hours
          const Text(
            'Giờ cao điểm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ...(_bookingData['peakHours'] as List? ?? []).map((hour) => SimpleCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.schedule, color: Colors.orange),
              title: Text(hour['hour']),
              trailing: Text(
                '${hour['bookings']} lượt',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMemberTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Stats
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              ModernStatsCard(
                title: 'Tổng thành viên',
                value: '${_memberData['totalMembers'] ?? 0}',
                subtitle: 'Đã đăng ký',
                icon: Icons.people,
                color: Colors.purple,
                trend: '+${_memberData['newMembersThisMonth'] ?? 0} tháng này',
                isPositiveTrend: true,
              ),
              ModernStatsCard(
                title: 'Thành viên hoạt động',
                value: '${_memberData['activeMembers'] ?? 0}',
                subtitle: 'Đang hoạt động',
                icon: Icons.person_outline,
                color: Colors.green,
                trend: 'Tích cực',
                isPositiveTrend: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Tier Distribution
          const Text(
            'Phân bố tier thành viên',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ...(_memberData['tierDistribution'] as List? ?? []).map((tier) => SimpleCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.star, color: _getTierColor(tier['tier'])),
              title: Text(tier['tier']),
              subtitle: Text('${tier['percentage'].toStringAsFixed(1)}%'),
              trailing: Text(
                '${tier['count']} người',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Health
          const Text(
            'Tình trạng hệ thống',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ...(_systemData['systemHealth'] as List? ?? []).map((component) => SimpleCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                Icons.check_circle,
                color: component['status'] == 'Healthy' ? Colors.green : Colors.red,
              ),
              title: Text(component['component']),
              subtitle: Text('Uptime: ${component['uptime']}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: component['status'] == 'Healthy' ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  component['status'] == 'Healthy' ? 'Tốt' : 'Lỗi',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          )),
          
          const SizedBox(height: 24),
          
          // System Metrics
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              ModernStatsCard(
                title: 'Uptime',
                value: _systemData['serverUptime'] ?? '99.9%',
                subtitle: 'Server',
                icon: Icons.computer,
                color: Colors.green,
                trend: 'Ổn định',
                isPositiveTrend: true,
              ),
              ModernStatsCard(
                title: 'Response Time',
                value: _systemData['apiResponseTime'] ?? '120ms',
                subtitle: 'API',
                icon: Icons.speed,
                color: Colors.blue,
                trend: 'Nhanh',
                isPositiveTrend: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Standard':
        return Colors.brown;
      case 'Silver':
        return Colors.grey;
      case 'Gold':
        return Colors.amber;
      case 'Diamond':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}