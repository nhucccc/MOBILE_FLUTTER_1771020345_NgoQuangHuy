import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/api_service.dart';

class TournamentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Tournament> _tournaments = [];
  List<Tournament> _myTournaments = [];
  List<TournamentParticipant> _participants = [];
  List<Match> _matches = [];
  bool _isLoading = false;
  String? _error;

  List<Tournament> get tournaments => _tournaments;
  List<Tournament> get myTournaments => _myTournaments;
  List<TournamentParticipant> get participants => _participants;
  List<Match> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Mock data for now - will be replaced with API calls
  Future<void> loadTournaments() async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock tournament data
      _tournaments = [
        Tournament(
          id: 1,
          name: 'Giải Pickleball Mùa Xuân 2024',
          startDate: DateTime.now().add(const Duration(days: 7)),
          endDate: DateTime.now().add(const Duration(days: 9)),
          format: 'Knockout',
          entryFee: 200000,
          prizePool: 5000000,
          status: 'Open',
        ),
        Tournament(
          id: 2,
          name: 'Giải Đấu Hàng Tuần #12',
          startDate: DateTime.now().add(const Duration(days: 14)),
          endDate: DateTime.now().add(const Duration(days: 14)),
          format: 'RoundRobin',
          entryFee: 100000,
          prizePool: 2000000,
          status: 'Registering',
        ),
        Tournament(
          id: 3,
          name: 'Giải Vô Địch CLB 2024',
          startDate: DateTime.now().add(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 32)),
          format: 'Hybrid',
          entryFee: 500000,
          prizePool: 15000000,
          status: 'Open',
        ),
      ];
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
  }

  Future<void> loadMyTournaments() async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data - tournaments user has joined
      _myTournaments = _tournaments.take(1).toList();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> joinTournament(int tournamentId) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Add to my tournaments if not already joined
      final tournament = _tournaments.firstWhere((t) => t.id == tournamentId);
      if (!_myTournaments.any((t) => t.id == tournamentId)) {
        _myTournaments.add(tournament);
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> leaveTournament(int tournamentId) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _myTournaments.removeWhere((t) => t.id == tournamentId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<Tournament?> getTournamentById(int tournamentId) async {
    try {
      // First check local cache
      final tournament = _tournaments.where((t) => t.id == tournamentId).firstOrNull;
      if (tournament != null) {
        return tournament;
      }

      // If not found locally, simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Return mock tournament for now
      return Tournament(
        id: tournamentId,
        name: 'Giải đấu #$tournamentId',
        startDate: DateTime.now().add(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 9)),
        format: 'Knockout',
        entryFee: 200000,
        prizePool: 5000000,
        status: 'Open',
      );
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<List<Match>> getTournamentMatches(int tournamentId) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Return mock matches
      _matches = [
        Match(
          id: 1,
          tournamentId: tournamentId,
          roundName: 'Vòng 1',
          date: DateTime.now().add(const Duration(days: 1)),
          startTime: DateTime.now().add(const Duration(days: 1, hours: 9)),
          team1Player1Name: 'Nguyễn Văn A',
          team2Player1Name: 'Trần Văn B',
          status: 'Scheduled',
        ),
        Match(
          id: 2,
          tournamentId: tournamentId,
          roundName: 'Vòng 1',
          date: DateTime.now().add(const Duration(days: 1)),
          startTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
          team1Player1Name: 'Lê Văn C',
          team2Player1Name: 'Phạm Văn D',
          status: 'Scheduled',
        ),
      ];
      
      notifyListeners();
      return _matches;
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  Future<List<TournamentParticipant>> getTournamentParticipants(int tournamentId) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Return mock participants
      _participants = [
        TournamentParticipant(
          id: 1,
          tournamentId: tournamentId,
          memberId: 1,
          memberName: 'Nguyễn Văn A',
          paymentStatus: 'Paid',
          joinedDate: DateTime.now().subtract(const Duration(days: 2)),
          duprRating: 3.5,
        ),
        TournamentParticipant(
          id: 2,
          tournamentId: tournamentId,
          memberId: 2,
          memberName: 'Trần Văn B',
          paymentStatus: 'Pending',
          joinedDate: DateTime.now().subtract(const Duration(days: 1)),
          duprRating: 4.0,
        ),
      ];
      
      notifyListeners();
      return _participants;
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper methods
  List<Tournament> get openTournaments {
    return _tournaments.where((t) => t.status == 'Open' || t.status == 'Registering').toList();
  }

  List<Tournament> get upcomingTournaments {
    final now = DateTime.now();
    return _myTournaments
        .where((t) => t.startDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  bool isJoined(int tournamentId) {
    return _myTournaments.any((t) => t.id == tournamentId);
  }
}