import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/tournament.dart';

// Enums for tournament functionality
enum TournamentFormat { RoundRobin, Knockout, Hybrid }
enum MatchStatus { Scheduled, InProgress, Finished }
enum WinningSide { Team1, Team2, Draw }
enum TournamentStatus { Open, Registering, DrawCompleted, Ongoing, Finished }

class TournamentBracket extends StatelessWidget {
  final Tournament tournament;
  final List<Match> matches;
  final Function(Match)? onMatchTap;

  const TournamentBracket({
    super.key,
    required this.tournament,
    required this.matches,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tournament.format == 'Knockout') {
      return _buildKnockoutBracket(context);
    } else {
      return _buildRoundRobinBracket(context);
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
              width: 200,
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                children: [
                  // Round header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
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
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
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

  Widget _buildMatchCard(Match match) {
    final isFinished = match.status == 'Finished';
    final hasWinner = match.winningSide != null;
    
    return GestureDetector(
      onTap: onMatchTap != null ? () => onMatchTap!(match) : null,
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
            if (match.date != null)
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
                  ],
                ),
              ),
          ],
        ),
      ),
    );
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
    
    for (final match in matches) {
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
    
    for (final match in matches) {
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