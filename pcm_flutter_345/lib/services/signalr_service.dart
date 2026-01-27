import 'package:signalr_netcore/signalr_client.dart';
import 'package:logger/logger.dart';
import 'api_service.dart';

class SignalRService {
  static const String hubUrl = 'http://localhost:58377/pcmhub'; // Update this to your backend URL
  
  HubConnection? _connection;
  final Logger _logger = Logger();
  final ApiService _apiService = ApiService();

  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;

  SignalRService._internal();

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    if (_connection?.state == HubConnectionState.Connected) {
      return;
    }

    try {
      final token = await _apiService.getToken();
      if (token == null) {
        _logger.w('No token available for SignalR connection');
        return;
      }

      _connection = HubConnectionBuilder()
          .withUrl(hubUrl, options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ))
          .withAutomaticReconnect()
          .build();

      _connection!.onclose(({Exception? error}) {
        _logger.w('SignalR connection closed: $error');
      });

      _connection!.onreconnecting(({Exception? error}) {
        _logger.i('SignalR reconnecting: $error');
      });

      _connection!.onreconnected(({String? connectionId}) {
        _logger.i('SignalR reconnected: $connectionId');
      });

      await _connection!.start();
      _logger.i('SignalR connected successfully');
    } catch (e) {
      _logger.e('Failed to connect to SignalR: $e');
    }
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
      _logger.i('SignalR disconnected');
    }
  }

  // Listen for notifications
  void onNotificationReceived(Function(Map<String, dynamic>) callback) {
    _connection?.on('ReceiveNotification', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final notification = arguments[0] as Map<String, dynamic>;
        callback(notification);
      }
    });
  }

  // Listen for calendar updates
  void onCalendarUpdated(Function() callback) {
    _connection?.on('UpdateCalendar', (arguments) {
      callback();
    });
  }

  // Listen for match score updates
  void onMatchScoreUpdated(Function(Map<String, dynamic>) callback) {
    _connection?.on('UpdateMatchScore', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final matchData = arguments[0] as Map<String, dynamic>;
        callback(matchData);
      }
    });
  }

  // Listen for wallet balance updates
  void onWalletUpdated(Function(double) callback) {
    _connection?.on('UpdateWallet', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final balance = (arguments[0] as num).toDouble();
        callback(balance);
      }
    });
  }

  // Send methods (if needed)
  Future<void> joinGroup(String groupName) async {
    if (_connection?.state == HubConnectionState.Connected) {
      try {
        await _connection!.invoke('JoinGroup', args: [groupName]);
        _logger.i('Joined SignalR group: $groupName');
      } catch (e) {
        _logger.e('Failed to join SignalR group: $e');
      }
    }
  }

  Future<void> leaveGroup(String groupName) async {
    if (_connection?.state == HubConnectionState.Connected) {
      try {
        await _connection!.invoke('LeaveGroup', args: [groupName]);
        _logger.i('Left SignalR group: $groupName');
      } catch (e) {
        _logger.e('Failed to leave SignalR group: $e');
      }
    }
  }
}