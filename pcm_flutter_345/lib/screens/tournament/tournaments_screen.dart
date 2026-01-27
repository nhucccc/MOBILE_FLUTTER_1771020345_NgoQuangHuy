import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../models/tournament.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';
import 'tournament_detail_screen.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    await Future.wait([
      provider.loadTournaments(),
      provider.loadMyTournaments(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Giải đấu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tất cả giải đấu'),
            Tab(text: 'Giải của tôi'),
          ],
        ),
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra',
                    style: AppTheme.headlineSmall.copyWith(
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllTournaments(provider),
              _buildMyTournaments(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAllTournaments(TournamentProvider provider) {
    if (provider.tournaments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có giải đấu nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadTournaments(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          kBottomNavigationBarHeight + 32,
        ),
        itemCount: provider.tournaments.length,
        itemBuilder: (context, index) {
          final tournament = provider.tournaments[index];
          return _buildTournamentCard(tournament, provider);
        },
      ),
    );
  }

  Widget _buildMyTournaments(TournamentProvider provider) {
    if (provider.myTournaments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Bạn chưa tham gia giải đấu nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy tham gia một giải đấu để bắt đầu!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadMyTournaments(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          kBottomNavigationBarHeight + 32,
        ),
        itemCount: provider.myTournaments.length,
        itemBuilder: (context, index) {
          final tournament = provider.myTournaments[index];
          return _buildTournamentCard(tournament, provider, isMyTournament: true);
        },
      ),
    );
  }

  Widget _buildTournamentCard(Tournament tournament, TournamentProvider provider, {bool isMyTournament = false}) {
    final isJoined = provider.isJoined(tournament.id);
    
    return SimpleCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentDetailScreen(tournamentId: tournament.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              Expanded(
                child: Text(
                  tournament.name,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(tournament.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tournament.statusDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Tournament info
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: AppTheme.neutral600,
              ),
              const SizedBox(width: 8),
              Text(
                '${tournament.startDate.day}/${tournament.startDate.month}/${tournament.startDate.year}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.neutral600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.sports_tennis,
                size: 16,
                color: AppTheme.neutral600,
              ),
              const SizedBox(width: 8),
              Text(
                tournament.formatDisplayName,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.neutral600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Prize and entry fee
          Row(
            children: [
              Icon(
                Icons.monetization_on,
                size: 16,
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Giải thưởng: ${_formatCurrency(tournament.prizePool)}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Phí: ${_formatCurrency(tournament.entryFee)}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.neutral600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action button
          if (!isMyTournament)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isJoined
                    ? () => _leaveTournament(tournament.id, provider)
                    : () => _joinTournament(tournament.id, provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isJoined ? AppTheme.errorColor : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(isJoined ? 'Rời khỏi giải' : 'Tham gia'),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
      case 'Registering':
        return AppTheme.successColor;
      case 'DrawCompleted':
        return AppTheme.warningColor;
      case 'Ongoing':
        return AppTheme.primaryColor;
      case 'Finished':
        return AppTheme.neutral500;
      default:
        return AppTheme.neutral400;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  Future<void> _joinTournament(int tournamentId, TournamentProvider provider) async {
    final success = await provider.joinTournament(tournamentId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Tham gia giải đấu thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Không thể tham gia giải đấu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveTournament(int tournamentId, TournamentProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn rời khỏi giải đấu này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rời khỏi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.leaveTournament(tournamentId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã rời khỏi giải đấu'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Không thể rời khỏi giải đấu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}