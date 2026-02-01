import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class FixedDashboardHomeScreen extends StatefulWidget {
  final Function(int)? onTabChange; // Thêm callback

  const FixedDashboardHomeScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  State<FixedDashboardHomeScreen> createState() => _FixedDashboardHomeScreenState();
}

class _FixedDashboardHomeScreenState extends State<FixedDashboardHomeScreen> {
  List<Map<String, dynamic>> topMembers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    await walletProvider.loadWalletData();
    await _loadTopMembers();
  }

  Future<void> _loadTopMembers() async {
    try {
      print('Loading top members from API...');
      final response = await http.get(
        Uri.parse('http://localhost:58377/api/admin/top-members'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            topMembers = List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
          print('Loaded ${topMembers.length} members');
          return;
        }
      }
      print('API call failed or returned no data');
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading top members: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Dashboard CLB',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Text(
                    user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20), // Tăng padding từ 16 lên 20
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(),
              const SizedBox(height: 32), // Tăng spacing từ 24 lên 32
              _buildQuickActions(),
              const SizedBox(height: 32), // Tăng spacing từ 24 lên 32
              _buildActivitySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        return Column(
          children: [
            // Row 1: Main stats
            Row(
              children: [
                _buildStatCard(
                  title: 'Thành viên',
                  value: '11',
                  subtitle: 'Hội viên',
                  color: Colors.blue,
                  icon: Icons.people_rounded,
                ),
                const SizedBox(width: 20), // Tăng spacing lên 20px
                _buildStatCard(
                  title: 'Sân',
                  value: '4',
                  subtitle: 'Hoạt động',
                  color: Colors.green,
                  icon: Icons.sports_tennis_rounded,
                ),
              ],
            ),
            const SizedBox(height: 20), // Tăng spacing lên 20px
            // Row 2: Secondary stats
            Row(
              children: [
                _buildStatCard(
                  title: 'Giải đấu',
                  value: '2',
                  subtitle: 'Thi đấu',
                  color: Colors.orange,
                  icon: Icons.emoji_events_rounded,
                ),
                const SizedBox(width: 20), // Tăng spacing lên 20px
                _buildStatCard(
                  title: 'Quỹ CLB',
                  value: '${(walletProvider.balance / 1000).toStringAsFixed(0)}K',
                  subtitle: 'Thu nhập',
                  color: Colors.purple,
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Flexible(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 100, // Tăng min height lên 100px
        ),
        padding: const EdgeInsets.all(16), // Tăng padding lên 16px
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16), // Tăng border radius lên 16px
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24), // Tăng icon size lên 24px
            const SizedBox(height: 8), // Thêm spacing
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28, // Tăng font size lên 28px
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14, // Tăng font size lên 14px
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hành động nhanh',
          style: TextStyle(
            fontSize: 22, // Tăng từ 20 lên 22
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20), // Tăng từ 16 lên 20
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Đặt sân',
                subtitle: 'Đặt sân nhanh',
                icon: Icons.sports_tennis_rounded,
                color: Colors.blue,
                onTap: () {
                  // Chuyển sang tab Lịch/Booking (index 1)
                  _navigateToTab(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Giải đấu',
                subtitle: 'Tham gia thi đấu',
                icon: Icons.emoji_events_rounded,
                color: Colors.orange,
                onTap: () {
                  // Chuyển sang tab Tournament (index 2)
                  _navigateToTab(2);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Ví tiền',
                subtitle: 'Quản lý tài chính',
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.green,
                onTap: () {
                  // Chuyển sang tab Wallet (index 3)
                  _navigateToTab(3);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToTab(int index) {
    // Dùng callback từ parent
    if (widget.onTabChange != null) {
      widget.onTabChange!(index);
    }
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap, // Thêm callback
  }) {
    return InkWell(
      onTap: onTap, // Thêm onTap
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoạt động gần đây',
          style: TextStyle(
            fontSize: 18, // Giảm từ 22 xuống 18
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16), // Giảm từ 20 xuống 16
        Column( // Thay Row bằng Column để tránh overflow
          children: [
            _buildRecentActivitiesCard(),
            const SizedBox(height: 16),
            _buildRankingCard(),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lịch sử hoạt động',
                style: TextStyle(
                  fontSize: 16, // Giảm từ 18 xuống 16
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<WalletProvider>(
            builder: (context, walletProvider, child) {
              final recentTransactions = walletProvider.recentTransactions;
              
              if (recentTransactions.isEmpty) {
                return _buildEmptyState();
              }
              
              return Column(
                children: [
                  ...recentTransactions.take(3).map((transaction) => 
                    _buildActivityItem(
                      icon: transaction.type == 'Deposit' 
                          ? Icons.add_circle_rounded 
                          : Icons.remove_circle_rounded,
                      title: transaction.type == 'Deposit' 
                          ? 'Nạp tiền vào ví' 
                          : 'Thanh toán đặt sân',
                      subtitle: '${transaction.amount.toStringAsFixed(0)} VNĐ',
                      time: _formatTime(transaction.createdDate),
                      color: transaction.type == 'Deposit' 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                  ).toList(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có hoạt động nào',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Widget _buildRankingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.leaderboard_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Bảng Xếp Hạng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              : topMembers.isEmpty
                  ? _buildEmptyRanking()
                  : Column(
                      children: topMembers.take(5).map((member) {
                        final index = topMembers.indexOf(member);
                        return _buildRankingItem(
                          index + 1,
                          member['fullName'] ?? 'Unknown',
                          member['duprRating']?.toString() ?? '0.0',
                          _getRankColor(index + 1),
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildEmptyRanking() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có dữ liệu xếp hạng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.blue;
    }
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
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
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(int rank, String name, String score, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: rank <= 3 ? color.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rank <= 3 ? color.withOpacity(0.2) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? color : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      rank == 1 ? Icons.emoji_events_rounded : 
                      rank == 2 ? Icons.military_tech_rounded : Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : Text(
                      rank.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Rating: $score',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: rank <= 3 ? color.withOpacity(0.1) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? color : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}