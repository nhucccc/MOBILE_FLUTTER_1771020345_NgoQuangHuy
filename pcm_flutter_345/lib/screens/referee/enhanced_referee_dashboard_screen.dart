import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';
import '../../widgets/modern_stats_card.dart';

class EnhancedRefereeDashboardScreen extends StatefulWidget {
  const EnhancedRefereeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedRefereeDashboardScreen> createState() => _EnhancedRefereeDashboardScreenState();
}

class _EnhancedRefereeDashboardScreenState extends State<EnhancedRefereeDashboardScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic> _stats = {};
  List<dynamic> _assignedMatches = [];
  List<dynamic> _upcomingTournaments = [];
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
      final statsResponse = await _apiService.get('/api/referee/dashboard-stats');
      final matchesResponse = await _apiService.get('/api/referee/assigned-matches');
      final tournamentsResponse = await _apiService.get('/api/referee/upcoming-tournaments');
      
      if (statsResponse['success'] && matchesResponse['success'] && tournamentsResponse['success']) {
        setState(() {
          _stats = statsResponse['data'];
          _assignedMatches = matchesResponse['data'];
          _upcomingTournaments = tournamentsResponse['data'];
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

  Future<void> _updateMatchScore(int matchId, int team1Score, int team2Score) async {
    try {
      final response = await _apiService.post('/api/referee/update-match-score', {
        'matchId': matchId,
        'team1Score': team1Score,
        'team2Score': team2Score,
      });

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã cập nhật tỷ số thành công'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload data
        await _loadDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${response['message'] ?? 'Không thể cập nhật tỷ số'}'),
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

  Future<void> _completeMatch(int matchId, int winnerTeamId) async {
    try {
      final response = await _apiService.post('/api/referee/complete-match', {
        'matchId': matchId,
        'winnerTeamId': winnerTeamId,
      });

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏆 Đã hoàn thành trận đấu'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload data
        await _loadDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${response['message'] ?? 'Không thể hoàn thành trận đấu'}'),
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
        title: const Text('Trọng Tài'),
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
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Icon(
                                  Icons.sports_handball,
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
                                      'Chào mừng, Trọng Tài!',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quản lý trận đấu và giải đấu với AI',
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

                        // Statistics
                        const Text(
                          'Thống kê trọng tài',
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
                              title: 'Trận được phân công',
                              value: '${_stats['assignedMatches'] ?? 0}',
                              subtitle: 'Hôm nay',
                              icon: Icons.assignment,
                              color: Colors.blue,
                              trend: 'Hôm nay',
                              isPositiveTrend: true,
                            ),
                            ModernStatsCard(
                              title: 'Trận đã hoàn thành',
                              value: '${_stats['completedMatches'] ?? 0}',
                              subtitle: 'Tuần này',
                              icon: Icons.check_circle,
                              color: Colors.green,
                              trend: 'Tuần này',
                              isPositiveTrend: true,
                            ),
                            ModernStatsCard(
                              title: 'Giải đấu tham gia',
                              value: '${_stats['activeTournaments'] ?? 0}',
                              subtitle: 'Đang diễn ra',
                              icon: Icons.emoji_events,
                              color: Colors.orange,
                              trend: 'Đang hoạt động',
                              isPositiveTrend: true,
                            ),
                            ModernStatsCard(
                              title: 'Đánh giá trung bình',
                              value: '${(_stats['averageRating'] ?? 0.0).toStringAsFixed(1)}⭐',
                              subtitle: 'Từ người chơi',
                              icon: Icons.star,
                              color: Colors.amber,
                              trend: 'Tổng thể',
                              isPositiveTrend: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Assigned Matches
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Trận đấu được phân công',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_assignedMatches.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_assignedMatches.length}',
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
                        
                        if (_assignedMatches.isEmpty)
                          SimpleCard(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_available,
                                  size: 64,
                                  color: Colors.blue.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Không có trận đấu nào được phân công',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Hãy kiểm tra lại sau',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._assignedMatches.map((match) => _buildMatchCard(match)).toList(),

                        const SizedBox(height: 32),

                        // Upcoming Tournaments
                        const Text(
                          'Giải đấu sắp tới',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (_upcomingTournaments.isEmpty)
                          SimpleCard(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  size: 64,
                                  color: Colors.orange.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Không có giải đấu nào sắp tới',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Hãy kiểm tra lại sau',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._upcomingTournaments.map((tournament) => _buildTournamentCard(tournament)).toList(),

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
                              'Lịch trọng tài',
                              'Xem lịch phân công',
                              Icons.schedule,
                              Colors.blue,
                              () => Navigator.pushNamed(context, '/referee/schedule'),
                            ),
                            _buildActionCard(
                              'Lịch sử trận đấu',
                              'Xem trận đã điều khiển',
                              Icons.history,
                              Colors.green,
                              () => Navigator.pushNamed(context, '/referee/match-history'),
                            ),
                            _buildActionCard(
                              'Báo cáo trận đấu',
                              'Tạo báo cáo chi tiết',
                              Icons.report,
                              Colors.orange,
                              () => Navigator.pushNamed(context, '/referee/match-reports'),
                            ),
                            _buildActionCard(
                              'Cài đặt trọng tài',
                              'Cấu hình cá nhân',
                              Icons.settings,
                              Colors.grey,
                              () => Navigator.pushNamed(context, '/referee/settings'),
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

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final isLive = match['status'] == 'InProgress';
    final isCompleted = match['status'] == 'Completed';
    
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
                  color: isLive ? Colors.red.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  isLive ? Icons.live_tv : Icons.sports_tennis,
                  color: isLive ? Colors.red : Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${match['team1Name']} vs ${match['team2Name']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Giải: ${match['tournamentName'] ?? 'Không rõ'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Thời gian: ${match['scheduledTime'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : (isLive ? Colors.red : Colors.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCompleted ? 'Hoàn thành' : (isLive ? 'Đang diễn ra' : 'Chờ bắt đầu'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          if (match['team1Score'] != null || match['team2Score'] != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${match['team1Score'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 20),
                const Text(
                  '-',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  '${match['team2Score'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Action Buttons
          if (!isCompleted) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showScoreUpdateDialog(match),
                    child: const Text('Cập nhật tỷ số'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLive ? () => _showCompleteMatchDialog(match) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive ? Colors.green : Colors.grey,
                    ),
                    child: Text(
                      isLive ? 'Hoàn thành' : 'Chưa bắt đầu',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTournamentCard(Map<String, dynamic> tournament) {
    return SimpleCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.emoji_events,
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
                  tournament['name'] ?? 'Không rõ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Bắt đầu: ${tournament['startDate'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Số trận: ${tournament['totalMatches'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/tournament-detail',
                arguments: tournament['id'],
              );
            },
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
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

  void _showScoreUpdateDialog(Map<String, dynamic> match) {
    final team1Controller = TextEditingController(text: '${match['team1Score'] ?? 0}');
    final team2Controller = TextEditingController(text: '${match['team2Score'] ?? 0}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật tỷ số'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: team1Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: match['team1Name'],
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: team2Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: match['team2Name'],
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final team1Score = int.tryParse(team1Controller.text) ?? 0;
              final team2Score = int.tryParse(team2Controller.text) ?? 0;
              Navigator.pop(context);
              _updateMatchScore(match['id'], team1Score, team2Score);
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showCompleteMatchDialog(Map<String, dynamic> match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành trận đấu'),
        content: Text('Bạn có chắc chắn muốn hoàn thành trận đấu "${match['team1Name']} vs ${match['team2Name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Determine winner based on scores
              final team1Score = match['team1Score'] ?? 0;
              final team2Score = match['team2Score'] ?? 0;
              final winnerTeamId = team1Score > team2Score ? match['team1Id'] : match['team2Id'];
              _completeMatch(match['id'], winnerTeamId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Hoàn thành', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}