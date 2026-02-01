import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';
import '../../widgets/tournament_bracket.dart';
import '../../models/tournament.dart';
import 'tournament_chat_screen.dart';

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
          title: const Text('Chi tiết giải'),
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
          title: const Text('Chi tiết giải'),
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
      floatingActionButton: _buildFloatingActionButtons(),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 64,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch thi đấu',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Lịch thi đấu sẽ được tạo sau khi đủ số lượng đội tham gia',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_tournament!.status == 'Registering')
              ElevatedButton.icon(
                onPressed: () => _generateBracket(),
                icon: const Icon(Icons.shuffle),
                label: const Text('Tạo lịch thi đấu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Bracket controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.neutral50,
            border: Border(
              bottom: BorderSide(color: AppTheme.neutral200),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Lịch thi đấu ${_getFormatText(_tournament!.format)}',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showBracketLegend(),
                icon: const Icon(Icons.help_outline),
                tooltip: 'Chú thích',
              ),
              IconButton(
                onPressed: () => _refreshBracket(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Làm mới',
              ),
            ],
          ),
        ),
        
        // Bracket widget
        Expanded(
          child: TournamentBracket(
            tournament: _tournament!,
            matches: _matches,
            onMatchTap: _showMatchDetail,
            isAdmin: _isAdmin(),
          ),
        ),
      ],
    );
  }

  bool _isAdmin() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.user?.role == 'Admin' || authProvider.user?.role == 'Referee';
  }

  Future<void> _generateBracket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo lịch thi đấu'),
        content: const Text(
          'Bạn có chắc chắn muốn tạo lịch thi đấu? '
          'Sau khi tạo, không thể thay đổi danh sách đội tham gia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Tạo lịch', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Call API to generate bracket
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang tạo lịch thi đấu...'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        
        await Future.delayed(const Duration(seconds: 2));
        await _loadTournamentData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo lịch thi đấu thành công!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo lịch: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _refreshBracket() async {
    await _loadTournamentData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã làm mới lịch thi đấu'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showBracketLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chú thích lịch thi đấu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem(
              color: AppTheme.neutral500,
              text: 'Chưa thi đấu',
              icon: Icons.schedule,
            ),
            _buildLegendItem(
              color: AppTheme.warningColor,
              text: 'Đang thi đấu',
              icon: Icons.play_circle,
            ),
            _buildLegendItem(
              color: AppTheme.successColor,
              text: 'Đã kết thúc',
              icon: Icons.check_circle,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nhấn vào trận đấu để xem chi tiết hoặc cập nhật kết quả (dành cho quản trị viên).',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String text,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab() {
    return Column(
      children: [
        // Participants header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.neutral50,
            border: Border(
              bottom: BorderSide(color: AppTheme.neutral200),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danh sách tham gia',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_participants.length}/${_tournament!.maxParticipants} đội',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isAdmin())
                ElevatedButton.icon(
                  onPressed: () => _showAddParticipantDialog(),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Thêm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ),
        
        // Participants list
        Expanded(
          child: _participants.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: AppTheme.neutral400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có đội tham gia',
                        style: AppTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _participants.length,
                  itemBuilder: (context, index) {
                    final participant = _participants[index];
                    
                    return SimpleCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (participant.duprRating != null && participant.duprRating! >= 4.0)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          participant.teamName ?? participant.memberName,
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              participant.memberName,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (participant.duprRating != null)
                              Text(
                                'DUPR: ${participant.duprRating!.toStringAsFixed(1)}',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
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
                            const SizedBox(height: 4),
                            Text(
                              '${participant.joinedDate.day}/${participant.joinedDate.month}',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showParticipantDetail(participant),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddParticipantDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm đội tham gia'),
        content: const Text('Chức năng này sẽ được phát triển sau.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showParticipantDetail(TournamentParticipant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(participant.teamName ?? participant.memberName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogInfoRow('Thành viên', participant.memberName),
            if (participant.teamName != null)
              _buildDialogInfoRow('Tên đội', participant.teamName!),
            if (participant.duprRating != null)
              _buildDialogInfoRow('DUPR Rating', participant.duprRating!.toStringAsFixed(1)),
            _buildDialogInfoRow('Trạng thái thanh toán', 
              participant.paymentStatus == 'Paid' ? 'Đã thanh toán' : 'Chưa thanh toán'),
            _buildDialogInfoRow('Ngày tham gia', 
              '${participant.joinedDate.day}/${participant.joinedDate.month}/${participant.joinedDate.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (_isAdmin() && participant.paymentStatus != 'Paid')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _markAsPaid(participant);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
              ),
              child: const Text('Đánh dấu đã thanh toán', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Future<void> _markAsPaid(TournamentParticipant participant) async {
    try {
      // TODO: Call API to mark as paid
      setState(() {
        participant.paymentStatus = 'Paid';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật trạng thái thanh toán'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
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

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButtons() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    // Check if user already joined
    final hasJoined = _participants.any((p) => p.memberId == user?.member?.id);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Chat button (always visible for participants)
        if (hasJoined || _isAdmin())
          FloatingActionButton(
            heroTag: "chat",
            onPressed: () => _openTournamentChat(),
            backgroundColor: AppTheme.warningColor,
            child: const Icon(Icons.chat, color: Colors.white),
          ),
        
        const SizedBox(height: 16),
        
        // Join/Leave button
        if (_tournament!.status == 'Registering' && !hasJoined)
          FloatingActionButton.extended(
            heroTag: "join",
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
          )
        else if (hasJoined && _tournament!.status == 'Registering')
          FloatingActionButton.extended(
            heroTag: "leave",
            onPressed: () => _leaveTournament(),
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Rời khỏi'),
          ),
      ],
    );
  }

  void _openTournamentChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentChatScreen(
          tournamentId: widget.tournamentId,
          tournamentName: _tournament!.name,
        ),
      ),
    );
  }

  Future<void> _leaveTournament() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời khỏi giải đấu'),
        content: const Text(
          'Bạn có chắc chắn muốn rời khỏi giải đấu này? '
          'Nếu đã thanh toán phí tham gia, bạn sẽ được hoàn lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Rời khỏi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final tournamentProvider = Provider.of<TournamentProvider>(context, listen: false);
        
        final success = await tournamentProvider.leaveTournament(widget.tournamentId);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã rời khỏi giải đấu'),
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
    }
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