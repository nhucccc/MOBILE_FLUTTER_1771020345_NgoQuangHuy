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

  // Load tournaments from API
  Future<void> loadTournaments() async {
    _setLoading(true);
    _clearError();

    try {
      print('TournamentProvider: Starting to load tournaments...'); // Debug log
      final response = await _apiService.get('/test/test-tournaments');
      print('TournamentProvider: Raw API response: $response'); // Debug log
      print('TournamentProvider: Response type: ${response.runtimeType}'); // Debug log
      
      List<dynamic> tournamentsData = [];
      
      if (response is Map<String, dynamic>) {
        print('TournamentProvider: Response is Map'); // Debug log
        if (response['success'] == true && response['data'] != null) {
          print('TournamentProvider: Found success=true and data'); // Debug log
          final data = response['data'];
          print('TournamentProvider: Data: $data'); // Debug log
          print('TournamentProvider: Data type: ${data.runtimeType}'); // Debug log
          
          if (data is List) {
            print('TournamentProvider: Data is List'); // Debug log
            tournamentsData = List<dynamic>.from(data);
          }
        }
      } else if (response is List) {
        print('TournamentProvider: Response is List'); // Debug log
        tournamentsData = response;
      }

      print('TournamentProvider: Final tournaments data: $tournamentsData'); // Debug log
      _tournaments = tournamentsData.map((json) => Tournament.fromJson(json)).toList();
      print('TournamentProvider: Loaded ${_tournaments.length} tournaments'); // Debug log
      
    } catch (e) {
      print('Error loading tournaments: $e');
      _setError('Lỗi tải danh sách giải đấu: $e');
      
      // Fallback to mock data if API fails
      print('Using fallback mock data');
      _tournaments = [
        Tournament(
          id: 1,
          name: 'Giải Pickleball Mùa Xuân 2024',
          startDate: DateTime.now().add(const Duration(days: 7)),
          endDate: DateTime.now().add(const Duration(days: 9)),
          format: 'Knockout',
          entryFee: 200000,
          prizePool: 5000000,
          status: 'Registering',
          maxParticipants: 32,
          participantCount: 12,
          description: 'Giải đấu pickleball lớn nhất mùa xuân với nhiều giải thưởng hấp dẫn',
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
          maxParticipants: 16,
          participantCount: 8,
          description: 'Giải đấu hàng tuần dành cho các thành viên CLB',
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
          maxParticipants: 64,
          participantCount: 24,
          description: 'Giải vô địch CLB với giải thưởng khủng',
        ),
      ];
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
      final response = await _apiService.post('/tournament/$tournamentId/join', {});
      
      if (response['success'] == true) {
        // Add to my tournaments if not already joined
        final tournament = _tournaments.firstWhere((t) => t.id == tournamentId);
        if (!_myTournaments.any((t) => t.id == tournamentId)) {
          _myTournaments.add(tournament);
        }
        
        // Increment participant count
        tournament.participantCount = (tournament.participantCount ?? 0) + 1;

        _setLoading(false);
        notifyListeners();
        
        // ✅ NEW: Wallet will be automatically updated via SignalR
        // No need to manually refresh here as WalletSyncService handles it
        
        return true;
      } else {
        throw Exception(response['message'] ?? 'Không thể tham gia giải đấu');
      }
    } catch (e) {
      _setError('Lỗi tham gia giải đấu: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> leaveTournament(int tournamentId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.post('/tournament/$tournamentId/leave', {});
      
      if (response['success'] == true) {
        _myTournaments.removeWhere((t) => t.id == tournamentId);
        
        // Decrement participant count
        final tournament = _tournaments.firstWhere((t) => t.id == tournamentId);
        tournament.participantCount = (tournament.participantCount ?? 1) - 1;

        _setLoading(false);
        notifyListeners();
        
        // ✅ NEW: Wallet will be automatically updated via SignalR if refund occurs
        // No need to manually refresh here as WalletSyncService handles it
        
        return true;
      } else {
        throw Exception(response['message'] ?? 'Không thể rời khỏi giải đấu');
      }
    } catch (e) {
      _setError('Lỗi rời khỏi giải đấu: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateTournament(int tournamentId, Map<String, dynamic> tournamentData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.put('/tournament/$tournamentId', tournamentData);
      
      if (response['success'] == true) {
        // Update tournament in local list
        final index = _tournaments.indexWhere((t) => t.id == tournamentId);
        if (index != -1) {
          _tournaments[index] = Tournament.fromJson(response['data']);
        }
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Không thể cập nhật giải đấu');
      }
    } catch (e) {
      _setError('Lỗi cập nhật giải đấu: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteTournament(int tournamentId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.delete('/tournament/$tournamentId');
      
      if (response['success'] == true) {
        // Remove tournament from local list
        _tournaments.removeWhere((t) => t.id == tournamentId);
        _myTournaments.removeWhere((t) => t.id == tournamentId);
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Không thể xóa giải đấu');
      }
    } catch (e) {
      _setError('Lỗi xóa giải đấu: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> cancelTournament(int tournamentId, String reason) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.post('/tournament/$tournamentId/cancel', {
        'reason': reason,
      });
      
      if (response['success'] == true) {
        // Update tournament status in local list
        final index = _tournaments.indexWhere((t) => t.id == tournamentId);
        if (index != -1) {
          _tournaments[index].status = 'Cancelled';
        }
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Không thể hủy giải đấu');
      }
    } catch (e) {
      _setError('Lỗi hủy giải đấu: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> generateBracket(int tournamentId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.post('/tournament/$tournamentId/generate-bracket', {});
      
      if (response['success'] == true) {
        // Update tournament status and load matches
        final index = _tournaments.indexWhere((t) => t.id == tournamentId);
        if (index != -1) {
          _tournaments[index].status = 'DrawCompleted';
        }
        
        // Load new matches
        await getTournamentMatches(tournamentId);
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Không thể tạo lịch thi đấu');
      }
    } catch (e) {
      _setError('Lỗi tạo lịch thi đấu: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateMatchResult(int tournamentId, int matchId, Map<String, dynamic> result) async {
    try {
      final response = await _apiService.put('/tournament/$tournamentId/match/$matchId', result);
      
      if (response['success'] == true) {
        // Update match in local list
        final matchIndex = _matches.indexWhere((m) => m.id == matchId);
        if (matchIndex != -1) {
          _matches[matchIndex] = Match.fromJson(response['data']);
        }
        
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Không thể cập nhật kết quả');
      }
    } catch (e) {
      _setError('Lỗi cập nhật kết quả: $e');
      return false;
    }
  }

  Future<List<Tournament>> searchTournaments(String query) async {
    try {
      final response = await _apiService.get('/tournament?search=$query');
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<dynamic> tournamentsData = [];
        
        if (data is Map<String, dynamic> && data.containsKey('tournaments')) {
          tournamentsData = List<dynamic>.from(data['tournaments']);
        } else if (data is List) {
          tournamentsData = List<dynamic>.from(data);
        }
        
        return tournamentsData.map((json) => Tournament.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      _setError('Lỗi tìm kiếm: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getTournamentStatistics(int tournamentId) async {
    try {
      final response = await _apiService.get('/tournament/$tournamentId/statistics');
      
      if (response['success'] == true && response['data'] != null) {
        return response['data'];
      }
      
      // Return mock statistics
      return {
        'totalMatches': _matches.length,
        'completedMatches': _matches.where((m) => m.status == 'Finished').length,
        'upcomingMatches': _matches.where((m) => m.status == 'Scheduled').length,
        'totalParticipants': _participants.length,
        'paidParticipants': _participants.where((p) => p.paymentStatus == 'Paid').length,
        'averageRating': _participants.isNotEmpty 
            ? _participants.map((p) => p.duprRating ?? 0).reduce((a, b) => a + b) / _participants.length
            : 0,
      };
    } catch (e) {
      _setError('Lỗi tải thống kê: $e');
      return {};
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

  void clearError() {
    _clearError();
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