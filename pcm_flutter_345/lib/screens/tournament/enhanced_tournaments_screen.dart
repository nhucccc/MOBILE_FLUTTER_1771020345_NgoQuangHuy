import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';
import '../../models/tournament.dart';

class EnhancedTournamentsScreen extends StatefulWidget {
  const EnhancedTournamentsScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedTournamentsScreen> createState() => _EnhancedTournamentsScreenState();
}

class _EnhancedTournamentsScreenState extends State<EnhancedTournamentsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadTournaments();
    await _loadWalletBalance();
  }

  Future<void> _loadTournaments() async {
    final tournamentProvider = Provider.of<TournamentProvider>(context, listen: false);
    setState(() {
      // Reset error state when loading
      tournamentProvider.clearError();
    });
    await tournamentProvider.loadTournaments();
  }

  Future<void> _loadWalletBalance() async {
    try {
      final response = await _apiService.get('/wallet/balance');
      print('Wallet API response: $response'); // Debug log
      
      if (response is Map<String, dynamic>) {
        if (response['success'] == true && response['data'] != null) {
          setState(() {
            _walletBalance = (response['data']['balance'] ?? 0.0).toDouble();
          });
        } else {
          print('Wallet API response format error: $response');
        }
      } else if (response is num) {
        // Fallback for direct number response
        setState(() {
          _walletBalance = response.toDouble();
        });
      }
    } catch (e) {
      print('Error loading wallet balance: $e');
    }
  }

  Future<void> _joinTournament(Tournament tournament) async {
    // Check entry fee
    if (tournament.entryFee > 0 && _walletBalance < tournament.entryFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Số dư không đủ để tham gia. Cần: ${tournament.entryFee.toStringAsFixed(0)}đ, Có: ${_walletBalance.toStringAsFixed(0)}đ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận tham gia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có muốn tham gia giải đấu "${tournament.name}"?'),
            if (tournament.entryFee > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Phí tham gia: ${tournament.entryFee.toStringAsFixed(0)}đ',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              Text('Số dư hiện tại: ${_walletBalance.toStringAsFixed(0)}đ'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Tham gia', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.post('/tournament/${tournament.id}/join', {});
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Đã tham gia giải đấu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload data
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${response['message'] ?? 'Không thể tham gia giải đấu'}'),
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTournamentCard(Tournament tournament) {
    final isRegistrationOpen = tournament.status == 'Registering';
    final canAfford = _walletBalance >= tournament.entryFee;
    
    return SimpleCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament Header
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tournament.description ?? 'Không có mô tả',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(tournament.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(tournament.status),
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
          
          // Tournament Info
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.calendar_today,
                  'Bắt đầu',
                  '${tournament.startDate.day}/${tournament.startDate.month}/${tournament.startDate.year}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.people,
                  'Tham gia',
                  '${tournament.participantCount}/${tournament.maxParticipants}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.attach_money,
                  'Phí tham gia',
                  tournament.entryFee > 0 ? '${tournament.entryFee.toStringAsFixed(0)}đ' : 'Miễn phí',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.emoji_events,
                  'Giải thưởng',
                  '${tournament.prizePool.toStringAsFixed(0)}đ',
                ),
              ),
            ],
          ),
          
          // Entry Fee Warning
          if (tournament.entryFee > 0 && !canAfford) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Số dư không đủ. Thiếu: ${(tournament.entryFee - _walletBalance).toStringAsFixed(0)}đ',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/tournament-detail',
                      arguments: tournament.id,
                    );
                  },
                  child: const Text('Xem chi tiết'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (isRegistrationOpen && canAfford && !_isLoading) 
                      ? () => _joinTournament(tournament)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRegistrationOpen && canAfford 
                        ? AppTheme.primaryColor 
                        : Colors.grey,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isRegistrationOpen 
                              ? (canAfford ? 'Tham gia' : 'Không đủ tiền')
                              : 'Đã đóng',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Registering':
        return Colors.green;
      case 'InProgress':
        return Colors.orange;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Registering':
        return 'Đang mở';
      case 'InProgress':
        return 'Đang diễn ra';
      case 'Completed':
        return 'Đã kết thúc';
      default:
        return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giải Đấu'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Wallet Balance
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_walletBalance.toStringAsFixed(0)}đ',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, tournamentProvider, child) {
          if (tournamentProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (tournamentProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(tournamentProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTournaments,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (tournamentProvider.tournaments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có giải đấu nào',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Hãy quay lại sau để xem các giải đấu mới'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tournamentProvider.tournaments.length,
              itemBuilder: (context, index) {
                final tournament = tournamentProvider.tournaments[index];
                return _buildTournamentCard(tournament);
              },
            ),
          );
        },
      ),
    );
  }
}