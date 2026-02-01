import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/tournament.dart';
import '../services/api_service.dart';

// Enums for tournament functionality
enum TournamentFormat { RoundRobin, Knockout, Hybrid }
enum MatchStatus { Scheduled, InProgress, Finished }
enum WinningSide { Team1, Team2, Draw }
enum TournamentStatus { Open, Registering, DrawCompleted, Ongoing, Finished }

class TournamentBracket extends StatefulWidget {
  final Tournament tournament;
  final List<Match> matches;
  final Function(Match)? onMatchTap;
  final bool isAdmin;

  const TournamentBracket({
    super.key,
    required this.tournament,
    required this.matches,
    this.onMatchTap,
    this.isAdmin = false,
  });

  @override
  State<TournamentBracket> createState() => _TournamentBracketState();
}

class _TournamentBracketState extends State<TournamentBracket> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    if (widget.tournament.format == 'Knockout') {
      return _buildKnockoutBracket(context);
    } else if (widget.tournament.format == 'RoundRobin') {
      return _buildRoundRobinBracket(context);
    } else {
      return _buildHybridBracket(context);
    }
  }

  Widget _buildKnockoutBracket(BuildContext context) {
    final rounds = _organizeMatchesByRound();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rounds.entries.map((entry) {
            final roundName = entry.key;
            final roundMatches = entry.value;
            
            return Container(
              width: 220,
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                children: [
                  // Round header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppTheme.shadowSM,
                    ),
                    child: Text(
                      roundName,
                      textAlign: TextAlign.center,
                      style: AppTheme.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Matches
                  ...roundMatches.asMap().entries.map((entry) {
                    final index = entry.key;
                    final match = entry.value;
                    return Container(
                      margin: EdgeInsets.only(
                        bottom: 16,
                        top: index > 0 ? _calculateMatchSpacing(roundName, index) : 0,
                      ),
                      child: _buildMatchCard(match),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoundRobinBracket(BuildContext context) {
    final groups = _organizeMatchesByGroup();
    
    return SingleChildScrollView(
      child: Column(
        children: groups.entries.map((entry) {
          final groupName = entry.key;
          final groupMatches = entry.value;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: AppTheme.shadowSM,
                  ),
                  child: Text(
                    groupName,
                    style: AppTheme.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Group standings table
                _buildGroupStandings(groupMatches),
                const SizedBox(height: 16),
                
                // Group matches
                ...groupMatches.map((match) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildMatchCard(match),
                )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHybridBracket(BuildContext context) {
    // Hybrid format: Group stage followed by knockout
    final groupMatches = widget.matches.where((m) => m.roundName?.contains('Group') == true).toList();
    final knockoutMatches = widget.matches.where((m) => !m.roundName!.contains('Group')).toList();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Stage
          if (groupMatches.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.shadowMD,
              ),
              child: Text(
                'VÒNG BẢNG',
                textAlign: TextAlign.center,
                style: AppTheme.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildGroupStageSection(groupMatches),
            const SizedBox(height: 32),
          ],
          
          // Knockout Stage
          if (knockoutMatches.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.red.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.shadowMD,
              ),
              child: Text(
                'VÒNG LOẠI TRỰC TIẾP',
                textAlign: TextAlign.center,
                style: AppTheme.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildKnockoutStageSection(knockoutMatches),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupStageSection(List<Match> groupMatches) {
    final groups = <String, List<Match>>{};
    for (final match in groupMatches) {
      final groupName = match.roundName ?? 'Group A';
      if (!groups.containsKey(groupName)) {
        groups[groupName] = [];
      }
      groups[groupName]!.add(match);
    }
    
    return Column(
      children: groups.entries.map((entry) {
        final groupName = entry.key;
        final matches = entry.value;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  groupName,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildGroupStandings(matches),
              const SizedBox(height: 12),
              ...matches.map((match) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: _buildMatchCard(match),
              )),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKnockoutStageSection(List<Match> knockoutMatches) {
    final rounds = <String, List<Match>>{};
    for (final match in knockoutMatches) {
      final roundName = match.roundName ?? 'Unknown Round';
      if (!rounds.containsKey(roundName)) {
        rounds[roundName] = [];
      }
      rounds[roundName]!.add(match);
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rounds.entries.map((entry) {
            final roundName = entry.key;
            final roundMatches = entry.value;
            
            return Container(
              width: 220,
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      roundName,
                      textAlign: TextAlign.center,
                      style: AppTheme.titleMedium.copyWith(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...roundMatches.map((match) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: _buildMatchCard(match),
                  )),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGroupStandings(List<Match> matches) {
    // Calculate standings from matches
    final standings = _calculateGroupStandings(matches);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(flex: 3, child: Text('Đội', style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(child: Text('Trận', style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(child: Text('Thắng', style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(child: Text('Thua', style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(child: Text('Điểm', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          // Standings rows
          ...standings.asMap().entries.map((entry) {
            final index = entry.key;
            final standing = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : AppTheme.neutral50,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: index < 2 ? AppTheme.successColor : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      standing['team'],
                      style: TextStyle(
                        fontWeight: index < 2 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(child: Text('${standing['played']}')),
                  Expanded(child: Text('${standing['won']}')),
                  Expanded(child: Text('${standing['lost']}')),
                  Expanded(
                    child: Text(
                      '${standing['points']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculateGroupStandings(List<Match> matches) {
    final standings = <String, Map<String, dynamic>>{};
    
    // Initialize standings for all teams
    for (final match in matches) {
      if (!standings.containsKey(match.team1Display)) {
        standings[match.team1Display] = {
          'team': match.team1Display,
          'played': 0,
          'won': 0,
          'lost': 0,
          'points': 0,
        };
      }
      if (!standings.containsKey(match.team2Display)) {
        standings[match.team2Display] = {
          'team': match.team2Display,
          'played': 0,
          'won': 0,
          'lost': 0,
          'points': 0,
        };
      }
    }
    
    // Calculate results from finished matches
    for (final match in matches.where((m) => m.status == 'Finished')) {
      final team1 = standings[match.team1Display]!;
      final team2 = standings[match.team2Display]!;
      
      team1['played']++;
      team2['played']++;
      
      if (match.winningSide == 'Team1') {
        team1['won']++;
        team1['points'] += 3;
        team2['lost']++;
      } else if (match.winningSide == 'Team2') {
        team2['won']++;
        team2['points'] += 3;
        team1['lost']++;
      } else {
        // Draw
        team1['points'] += 1;
        team2['points'] += 1;
      }
    }
    
    // Sort by points, then by wins
    final sortedStandings = standings.values.toList();
    sortedStandings.sort((a, b) {
      final pointsCompare = b['points'].compareTo(a['points']);
      if (pointsCompare != 0) return pointsCompare;
      return b['won'].compareTo(a['won']);
    });
    
    return sortedStandings;
  }

  double _calculateMatchSpacing(String roundName, int index) {
    // Calculate spacing between matches in knockout rounds
    switch (roundName) {
      case 'Semi Final':
        return 60.0;
      case 'Final':
        return 120.0;
      default:
        return 0.0;
    }
  }

  Widget _buildMatchCard(Match match) {
    final isFinished = match.status == 'Finished';
    final hasWinner = match.winningSide != null;
    
    return GestureDetector(
      onTap: () => _handleMatchTap(match),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFinished 
                ? AppTheme.successColor 
                : match.status == 'InProgress'
                    ? AppTheme.warningColor
                    : AppTheme.neutral300,
            width: 2,
          ),
          boxShadow: AppTheme.shadowSM,
        ),
        child: Column(
          children: [
            // Match header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: _getMatchStatusColor(match.status).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Match ${match.id}',
                    style: AppTheme.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getMatchStatusColor(match.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getMatchStatusText(match.status),
                          style: AppTheme.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.isAdmin && match.status != 'Finished') ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showMatchManagementDialog(match),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Teams
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Team 1
                  _buildTeamRow(
                    teamName: match.team1Display,
                    score: match.score1,
                    isWinner: hasWinner && match.winningSide == 'Team1',
                    isLoser: hasWinner && match.winningSide == 'Team2',
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // VS divider
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: AppTheme.neutral200,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.white,
                        child: Text(
                          'VS',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Team 2
                  _buildTeamRow(
                    teamName: match.team2Display,
                    score: match.score2,
                    isWinner: hasWinner && match.winningSide == 'Team2',
                    isLoser: hasWinner && match.winningSide == 'Team1',
                  ),
                ],
              ),
            ),
            
            // Match details
            if (match.date != null || match.startTime != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.neutral50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (match.date != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${match.date!.day}/${match.date!.month}',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    if (match.startTime != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${match.startTime!.hour.toString().padLeft(2, '0')}:${match.startTime!.minute.toString().padLeft(2, '0')}',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    if (match.courtName != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.sports_tennis,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            match.courtName!,
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleMatchTap(Match match) {
    if (widget.onMatchTap != null) {
      widget.onMatchTap!(match);
    } else {
      _showMatchDetailDialog(match);
    }
  }

  void _showMatchDetailDialog(Match match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.sports_tennis,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text('Match ${match.id}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teams
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.neutral50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        if (match.score1 != null)
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        if (match.score2 != null)
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
              
              const SizedBox(height: 16),
              
              // Match info
              _buildInfoRow('Vòng đấu', match.roundName ?? 'N/A'),
              _buildInfoRow('Trạng thái', _getMatchStatusText(match.status)),
              if (match.date != null)
                _buildInfoRow('Ngày', '${match.date!.day}/${match.date!.month}/${match.date!.year}'),
              if (match.startTime != null)
                _buildInfoRow('Giờ', '${match.startTime!.hour.toString().padLeft(2, '0')}:${match.startTime!.minute.toString().padLeft(2, '0')}'),
              if (match.courtName != null)
                _buildInfoRow('Sân', match.courtName!),
              if (match.details != null && match.details!.isNotEmpty)
                _buildInfoRow('Chi tiết', match.details!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          if (widget.isAdmin && match.status != 'Finished')
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showMatchManagementDialog(match);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Quản lý', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  void _showMatchManagementDialog(Match match) {
    final score1Controller = TextEditingController(text: match.score1?.toString() ?? '');
    final score2Controller = TextEditingController(text: match.score2?.toString() ?? '');
    final detailsController = TextEditingController(text: match.details ?? '');
    String selectedStatus = match.status;
    String? selectedWinner = match.winningSide;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Quản lý Match ${match.id}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Scheduled', 'InProgress', 'Finished'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_getMatchStatusText(status)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Scores
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: score1Controller,
                        decoration: InputDecoration(
                          labelText: match.team1Display,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: score2Controller,
                        decoration: InputDecoration(
                          labelText: match.team2Display,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Winner (if finished)
                if (selectedStatus == 'Finished')
                  DropdownButtonFormField<String>(
                    value: selectedWinner,
                    decoration: const InputDecoration(
                      labelText: 'Người thắng',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Chưa xác định')),
                      DropdownMenuItem(value: 'Team1', child: Text(match.team1Display)),
                      DropdownMenuItem(value: 'Team2', child: Text(match.team2Display)),
                      const DropdownMenuItem(value: 'Draw', child: Text('Hòa')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedWinner = value;
                      });
                    },
                  ),
                
                const SizedBox(height: 16),
                
                // Details
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateMatchResult(
                  match,
                  selectedStatus,
                  int.tryParse(score1Controller.text),
                  int.tryParse(score2Controller.text),
                  selectedWinner,
                  detailsController.text,
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Cập nhật', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateMatchResult(
    Match match,
    String status,
    int? score1,
    int? score2,
    String? winningSide,
    String details,
  ) async {
    try {
      await _apiService.put('/tournament/${match.tournamentId}/match/${match.id}', {
        'status': status,
        'score1': score1,
        'score2': score2,
        'winningSide': winningSide,
        'details': details,
      });

      // Update local match data
      setState(() {
        match.status = status;
        match.score1 = score1;
        match.score2 = score2;
        match.winningSide = winningSide;
        match.details = details;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật kết quả thành công!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildTeamRow({
    required String teamName,
    int? score,
    bool isWinner = false,
    bool isLoser = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            teamName,
            style: AppTheme.titleMedium.copyWith(
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              color: isWinner 
                  ? AppTheme.successColor 
                  : isLoser 
                      ? AppTheme.textSecondary 
                      : AppTheme.textPrimary,
            ),
          ),
        ),
        if (score != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isWinner 
                  ? AppTheme.successColor 
                  : isLoser 
                      ? AppTheme.neutral300 
                      : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              score.toString(),
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isWinner 
                    ? Colors.white 
                    : isLoser 
                        ? AppTheme.textSecondary 
                        : AppTheme.primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  Map<String, List<Match>> _organizeMatchesByRound() {
    final rounds = <String, List<Match>>{};
    
    for (final match in widget.matches) {
      final roundName = match.roundName ?? 'Unknown Round';
      if (!rounds.containsKey(roundName)) {
        rounds[roundName] = [];
      }
      rounds[roundName]!.add(match);
    }
    
    // Sort rounds by typical tournament progression
    final sortedRounds = <String, List<Match>>{};
    final roundOrder = [
      'Round of 32',
      'Round of 16', 
      'Quarter Final',
      'Semi Final',
      'Final',
      'Third Place',
    ];
    
    for (final roundName in roundOrder) {
      if (rounds.containsKey(roundName)) {
        sortedRounds[roundName] = rounds[roundName]!;
      }
    }
    
    // Add any remaining rounds
    for (final entry in rounds.entries) {
      if (!sortedRounds.containsKey(entry.key)) {
        sortedRounds[entry.key] = entry.value;
      }
    }
    
    return sortedRounds;
  }

  Map<String, List<Match>> _organizeMatchesByGroup() {
    final groups = <String, List<Match>>{};
    
    for (final match in widget.matches) {
      final groupName = match.roundName ?? 'Group A';
      if (!groups.containsKey(groupName)) {
        groups[groupName] = [];
      }
      groups[groupName]!.add(match);
    }
    
    return groups;
  }

  Color _getMatchStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return AppTheme.neutral500;
      case 'InProgress':
        return AppTheme.warningColor;
      case 'Finished':
        return AppTheme.successColor;
      default:
        return AppTheme.neutral500;
    }
  }

  String _getMatchStatusText(String status) {
    switch (status) {
      case 'Scheduled':
        return 'Chưa đấu';
      case 'InProgress':
        return 'Đang đấu';
      case 'Finished':
        return 'Kết thúc';
      default:
        return status;
    }
  }
}

// Bracket Connection Painter for visual connections between matches
class BracketConnectionPainter extends CustomPainter {
  final List<Match> matches;
  final Color lineColor;

  BracketConnectionPainter({
    required this.matches,
    this.lineColor = AppTheme.neutral300,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw connections between rounds
    // This is a simplified version - in a real implementation,
    // you'd calculate exact positions based on match positions
    
    final path = Path();
    
    // Example: Draw lines connecting matches
    // You would implement the actual bracket connection logic here
    // based on your tournament structure
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}