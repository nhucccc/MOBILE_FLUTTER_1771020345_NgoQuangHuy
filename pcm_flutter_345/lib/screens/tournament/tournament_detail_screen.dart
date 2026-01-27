import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';
import '../../widgets/tournament_bracket.dart';
import '../../models/tournament.dart';

class TournamentDetailScreen extends StatefulWidget {
  final int tournamentId;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Tournament? _tournament;
  List<Match> _matches = [];
  List<TournamentParticipant> _participants = [];
  bool _isLoading = true;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTournamentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTournamentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tournamentProvider = Provider.of<TournamentProvider>(context, listen: false);
      
      // Load tournament details
      _tournament = await tournamentProvider.getTournamentById(widget.tournamentId);
      _matches = await tournamentProvider.getTournamentMatches(widget.tournamentId);
      _participants = await tournamentProvider.getTournamentParticipants(widget.tournamentId);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết giải đấu'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_tournament == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết giải đấu'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Không tìm thấy giải đấu'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_tournament!.name),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Thông tin'),
            Tab(text: 'Bracket'),
            Tab(text: 'Thành viên'),
            Tab(text: 'Kết quả'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildBracketTab(),
          _buildParticipantsTab(),
          _buildResultsTab(),
        ],
      ),
      floatingActionButton: _buildJoinButton(),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament Header
          SimpleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tournament!.name,
                            style: AppTheme.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_tournament!.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(_tournament!.status),
                              style: AppTheme.labelMedium.copyWith(
                                color: _getStatusColor(_tournament!.status),
                                fontWeight: FontWeight.w600,
                              ),
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

          const SizedBox(height: 16),

          // Tournament Details
          SimpleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin giải đấu',
                  style: AppTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Thời gian',
                  value: '${_tournament!.startDate.day}/${_tournament!.startDate.month}/${_tournament!.startDate.year} - ${_tournament!.endDate.day}/${_tournament!.endDate.month}/${_tournament!.endDate.year}',
                ),
                
                _buildInfoRow(
                  icon: Icons.sports,
                  label: 'Thể thức',
                  value: _getFormatText(_tournament!.format),
                ),
                
                _buildInfoRow(
                  icon: Icons.attach_money,
                  label: 'Phí tham gia',
                  value: '${_tournament!.entryFee.toStringAsFixed(0)}đ',
                ),
                
                _buildInfoRow(
                  icon: Icons.emoji_events,
                  label: 'Giải thưởng',
                  value: '${_tournament!.prizePool.toStringAsFixed(0)}đ',
                ),
                
                _buildInfoRow(
                  icon: Icons.people,
                  label: 'Số đội tham gia',
                  value: '${_participants.length} đội',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tournament Description
          SimpleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mô tả',
                  style: AppTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Thông tin chi tiết về giải đấu sẽ được cập nhật sau.',
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketTab() {
    if (_matches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 64,
              color: AppTheme.neutral400,
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có lịch thi đấu',
              style: AppTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return TournamentBracket(
      tournament: _tournament!,
      matches: _matches,
      onMatchTap: _showMatchDetail,
    );
  }

  Widget _buildParticipantsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final participant = _participants[index];
        
        return SimpleCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              participant.teamName ?? participant.memberName,
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              participant.memberName,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: participant.paymentStatus == 'Paid' 
                    ? AppTheme.successColor.withOpacity(0.1)
                    : AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                participant.paymentStatus == 'Paid' ? 'Đã thanh toán' : 'Chưa thanh toán',
                style: AppTheme.labelSmall.copyWith(
                  color: participant.paymentStatus == 'Paid' 
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsTab() {
    final finishedMatches = _matches.where((m) => m.status == 'Finished').toList();
    
    if (finishedMatches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_score,
              size: 64,
              color: AppTheme.neutral400,
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có kết quả',
              style: AppTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: finishedMatches.length,
      itemBuilder: (context, index) {
        final match = finishedMatches[index];
        
        return SimpleCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  '${match.roundName} - Match ${match.id}',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
              
              // Match result
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.team1Display,
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: match.winningSide == 'Team1' 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              color: match.winningSide == 'Team1' 
                                  ? AppTheme.successColor 
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            match.team2Display,
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: match.winningSide == 'Team2' 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              color: match.winningSide == 'Team2' 
                                  ? AppTheme.successColor 
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: match.winningSide == 'Team1' 
                                ? AppTheme.successColor 
                                : AppTheme.neutral300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${match.score1}',
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: match.winningSide == 'Team1' 
                                  ? Colors.white 
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: match.winningSide == 'Team2' 
                                ? AppTheme.successColor 
                                : AppTheme.neutral300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${match.score2}',
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: match.winningSide == 'Team2' 
                                  ? Colors.white 
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Match details
              if (match.details != null && match.details!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Chi tiết: ${match.details}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildJoinButton() {
    if (_tournament == null || 
        _tournament!.status != 'Registering') {
      return null;
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    // Check if user already joined
    final hasJoined = _participants.any((p) => p.memberId == user?.member?.id);
    
    if (hasJoined) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: _isJoining ? null : _joinTournament,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: _isJoining 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.add),
      label: Text(_isJoining ? 'Đang tham gia...' : 'Tham gia'),
    );
  }

  Future<void> _joinTournament() async {
    setState(() {
      _isJoining = true;
    });

    try {
      final tournamentProvider = Provider.of<TournamentProvider>(context, listen: false);
      
      final success = await tournamentProvider.joinTournament(widget.tournamentId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tham gia giải đấu thành công!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Reload data
        await _loadTournamentData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    setState(() {
      _isJoining = false;
    });
  }

  void _showMatchDetail(Match match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Match ${match.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${match.team1Display} vs ${match.team2Display}'),
            if (match.status == 'Finished') ...[
              const SizedBox(height: 8),
              Text('Kết quả: ${match.score1} - ${match.score2}'),
              if (match.details != null && match.details!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Chi tiết: ${match.details}'),
              ],
            ],
            if (match.date != null) ...[
              const SizedBox(height: 8),
              Text('Ngày: ${match.date!.day}/${match.date!.month}/${match.date!.year}'),
            ],
            if (match.startTime != null) ...[
              const SizedBox(height: 8),
              Text('Giờ: ${match.startTime!.hour.toString().padLeft(2, '0')}:${match.startTime!.minute.toString().padLeft(2, '0')}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return AppTheme.infoColor;
      case 'Registering':
        return AppTheme.warningColor;
      case 'DrawCompleted':
        return AppTheme.primaryColor;
      case 'Ongoing':
        return AppTheme.successColor;
      case 'Finished':
        return AppTheme.neutral500;
      default:
        return AppTheme.neutral500;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Open':
        return 'Mở đăng ký';
      case 'Registering':
        return 'Đang đăng ký';
      case 'DrawCompleted':
        return 'Đã bốc thăm';
      case 'Ongoing':
        return 'Đang diễn ra';
      case 'Finished':
        return 'Kết thúc';
      default:
        return status;
    }
  }

  String _getFormatText(String format) {
    switch (format) {
      case 'RoundRobin':
        return 'Vòng tròn';
      case 'Knockout':
        return 'Loại trực tiếp';
      case 'Hybrid':
        return 'Kết hợp';
      default:
        return format;
    }
  }
}