import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  bool _isConnected = false;
  bool _isDisposed = false;
  String? _currentUserId;
  Timer? _heartbeatTimer;
  
  // Track joined groups for reconnection
  final Set<String> _joinedGroups = <String>{};
  
  // Event streams
  final StreamController<Map<String, dynamic>> _notificationController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _walletUpdateController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _bookingUpdateController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _slotStatusController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _tournamentUpdateController = StreamController.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;
  Stream<Map<String, dynamic>> get walletUpdateStream => _walletUpdateController.stream;
  Stream<Map<String, dynamic>> get bookingUpdateStream => _bookingUpdateController.stream;
  Stream<Map<String, dynamic>> get slotStatusStream => _slotStatusController.stream;
  Stream<Map<String, dynamic>> get tournamentUpdateStream => _tournamentUpdateController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect(String userId, String accessToken) async {
    if (_isDisposed) {
      print('❌ SignalR service is disposed, cannot connect');
      return;
    }

    if (_isConnected && _currentUserId == userId && _hubConnection != null) {
      // Check connection health with ping
      try {
        await _hubConnection!.invoke('Ping');
        print('✅ SignalR connection is healthy for user $userId');
        return;
      } catch (e) {
        print('🔄 Connection unhealthy, reconnecting: $e');
        await disconnect();
      }
    }

    try {
      await disconnect();

      final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
      
      _hubConnection = HubConnectionBuilder()
          .withUrl('$baseUrl/pcmhub', options: HttpConnectionOptions(
            accessTokenFactory: () async => accessToken,
          ))
          .withAutomaticReconnect()
          .build();

      _setupEventHandlers();

      await _hubConnection!.start();
      _isConnected = true;
      _currentUserId = userId;

      print('✅ SignalR connected successfully for user $userId');
      
      // Join user-specific group
      await _hubConnection!.invoke('JoinUserGroup', args: [userId]);
      
      // Rejoin all previously joined groups
      await _rejoinAllGroups();
      
      // Start heartbeat
      _startHeartbeat();
      
    } catch (e) {
      print('❌ SignalR connection failed: $e');
      _isConnected = false;
    }
  }

  void _setupEventHandlers() {
    if (_hubConnection == null) return;

    // Notification Events
    _hubConnection!.on('ReceiveNotification', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _notificationController.add(data);
        print('📢 Received notification: ${data['title']}');
      }
    });

    // Wallet Events
    _hubConnection!.on('UpdateWalletBalance', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _walletUpdateController.add(data);
        print('💰 Wallet updated: ${data['balance']}');
      }
    });

    _hubConnection!.on('WalletDepositApproved', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _walletUpdateController.add({
          'type': 'deposit_approved',
          'data': data,
        });
        print('✅ Deposit approved: ${data['amount']}');
      }
    });

    _hubConnection!.on('WalletDepositRejected', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _walletUpdateController.add({
          'type': 'deposit_rejected',
          'data': data,
        });
        print('❌ Deposit rejected: ${data['amount']}');
      }
    });

    // Booking Events
    _hubConnection!.on('BookingCreated', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _bookingUpdateController.add({
          'type': 'booking_created',
          'data': data,
        });
        print('🏟️ Booking created: ${data['courtName']}');
      }
    });

    _hubConnection!.on('BookingCancelled', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _bookingUpdateController.add({
          'type': 'booking_cancelled',
          'data': data,
        });
        print('❌ Booking cancelled: ${data['courtName']}');
      }
    });

    _hubConnection!.on('RefreshCalendar', (arguments) {
      _bookingUpdateController.add({
        'type': 'refresh_calendar',
        'data': {},
      });
      print('🔄 Calendar refresh requested');
    });

    // Slot Reservation Events
    _hubConnection!.on('SlotStatusChanged', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _slotStatusController.add(data);
        print('🎯 Slot status changed: Court ${data['courtId']} - ${data['status']}');
      }
    });

    _hubConnection!.on('SlotReserved', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _slotStatusController.add({
          'type': 'slot_reserved',
          'data': data,
        });
        print('⏰ Slot reserved: Court ${data['courtId']}');
      }
    });

    _hubConnection!.on('SlotReleased', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _slotStatusController.add({
          'type': 'slot_released',
          'data': data,
        });
        print('🔓 Slot released: Court ${data['courtId']}');
      }
    });

    _hubConnection!.on('SlotExpired', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _slotStatusController.add({
          'type': 'slot_expired',
          'data': data,
        });
        print('⏰ Slot expired: Court ${data['courtId']}');
      }
    });

    // Tournament Events
    _hubConnection!.on('TournamentRegistrationOpened', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _tournamentUpdateController.add({
          'type': 'registration_opened',
          'data': data,
        });
        print('🏆 Tournament registration opened: ${data['name']}');
      }
    });

    _hubConnection!.on('TournamentBracketUpdated', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _tournamentUpdateController.add({
          'type': 'bracket_updated',
          'data': data,
        });
        print('🏆 Tournament bracket updated: ${data['tournamentId']}');
      }
    });

    _hubConnection!.on('MatchScoreUpdated', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _tournamentUpdateController.add({
          'type': 'match_score_updated',
          'data': data,
        });
        print('⚽ Match score updated: ${data['matchId']}');
      }
    });

    // Connection Events
    _hubConnection!.onclose(({Exception? error}) {
      print('❌ SignalR connection closed: $error');
      _isConnected = false;
      _stopHeartbeat();
    });

    _hubConnection!.onreconnecting(({Exception? error}) {
      print('🔄 SignalR reconnecting: $error');
      _isConnected = false;
      _stopHeartbeat();
    });

    _hubConnection!.onreconnected(({String? connectionId}) {
      print('✅ SignalR reconnected: $connectionId');
      _isConnected = true;
      
      // Rejoin user group after reconnection
      if (_currentUserId != null) {
        _hubConnection!.invoke('JoinUserGroup', args: [_currentUserId!]);
      }
      
      // Rejoin all previously joined groups
      _rejoinAllGroups();
      
      // Restart heartbeat
      _startHeartbeat();
    });
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isConnected && _hubConnection != null && !_isDisposed) {
        try {
          await _hubConnection!.invoke('Ping');
          print('💓 SignalR heartbeat OK');
        } catch (e) {
          print('💔 SignalR heartbeat failed, will reconnect: $e');
          // Let automatic reconnection handle this
        }
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _rejoinAllGroups() async {
    if (_hubConnection == null || !_isConnected) return;
    
    for (final group in _joinedGroups) {
      try {
        if (group.startsWith('court_')) {
          final courtId = group.split('_')[1];
          await _hubConnection!.invoke('JoinCourtGroup', args: [courtId]);
          print('🔄 Rejoined court group: $courtId');
        } else if (group.startsWith('tournament_')) {
          final tournamentId = group.split('_')[1];
          await _hubConnection!.invoke('JoinTournamentGroup', args: [tournamentId]);
          print('🔄 Rejoined tournament group: $tournamentId');
        }
      } catch (e) {
        print('❌ Failed to rejoin group $group: $e');
      }
    }
  }

  Future<void> disconnect() async {
    try {
      _stopHeartbeat();
      
      if (_hubConnection != null) {
        await _hubConnection!.stop();
        _hubConnection = null;
      }
      _isConnected = false;
      _currentUserId = null;
      print('✅ SignalR disconnected');
    } catch (e) {
      print('❌ SignalR disconnect error: $e');
    }
  }

  // Join specific groups
  Future<void> joinTournamentGroup(int tournamentId) async {
    if (_isConnected && _hubConnection != null) {
      try {
        await _hubConnection!.invoke('JoinTournamentGroup', args: [tournamentId.toString()]);
        _joinedGroups.add('tournament_$tournamentId');
        print('✅ Joined tournament group: $tournamentId');
      } catch (e) {
        print('❌ Failed to join tournament group: $e');
      }
    }
  }

  Future<void> leaveTournamentGroup(int tournamentId) async {
    if (_isConnected && _hubConnection != null) {
      try {
        await _hubConnection!.invoke('LeaveTournamentGroup', args: [tournamentId.toString()]);
        _joinedGroups.remove('tournament_$tournamentId');
        print('✅ Left tournament group: $tournamentId');
      } catch (e) {
        print('❌ Failed to leave tournament group: $e');
      }
    }
  }

  Future<void> joinCourtGroup(int courtId) async {
    if (_isConnected && _hubConnection != null) {
      try {
        await _hubConnection!.invoke('JoinCourtGroup', args: [courtId.toString()]);
        _joinedGroups.add('court_$courtId');
        print('✅ Joined court group: $courtId');
      } catch (e) {
        print('❌ Failed to join court group: $e');
      }
    }
  }

  Future<void> leaveCourtGroup(int courtId) async {
    if (_isConnected && _hubConnection != null) {
      try {
        await _hubConnection!.invoke('LeaveCourtGroup', args: [courtId.toString()]);
        _joinedGroups.remove('court_$courtId');
        print('✅ Left court group: $courtId');
      } catch (e) {
        print('❌ Failed to leave court group: $e');
      }
    }
  }

  // Send typing indicator for chat
  Future<void> sendTypingIndicator(int tournamentId, bool isTyping) async {
    if (_isConnected && _hubConnection != null) {
      try {
        await _hubConnection!.invoke('SendTypingIndicator', args: [tournamentId, isTyping]);
      } catch (e) {
        print('❌ Failed to send typing indicator: $e');
      }
    }
  }

  void dispose() {
    _isDisposed = true;
    _stopHeartbeat();
    
    if (!_notificationController.isClosed) _notificationController.close();
    if (!_walletUpdateController.isClosed) _walletUpdateController.close();
    if (!_bookingUpdateController.isClosed) _bookingUpdateController.close();
    if (!_slotStatusController.isClosed) _slotStatusController.close();
    if (!_tournamentUpdateController.isClosed) _tournamentUpdateController.close();
    
    disconnect();
  }
}