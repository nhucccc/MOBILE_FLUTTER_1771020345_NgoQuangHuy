import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';

class WalletProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SignalRService _signalRService = SignalRService();

  double _balance = 0.0;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  
  // Prevent concurrent loading
  Future<void>? _loadingFuture;

  double get balance => _balance;
  List<WalletTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Debug: Hot reload trigger
  WalletProvider() {
    _setupSignalRListeners();
    // Auto-load wallet data when provider is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadWalletData();
    });
  }

  void _setupSignalRListeners() {
    _signalRService.walletUpdateStream.listen((data) {
      print('💰 Received wallet update: $data');
      
      if (data['balance'] != null) {
        final newBalance = data['balance'].toDouble();
        
        // Validate update makes sense
        if (newBalance >= 0 && (newBalance != _balance)) {
          final oldBalance = _balance;
          _balance = newBalance;
          
          print('💰 Wallet updated: $oldBalance → $newBalance');
          
          // Reload transactions to stay in sync if there's a transaction ID
          if (data['transactionId'] != null) {
            loadTransactions(page: 1);
          }
          
          notifyListeners();
        }
      }
      
      // Handle different wallet update types
      if (data['type'] != null) {
        switch (data['type']) {
          case 'deposit_approved':
            _handleDepositApproved(data['data']);
            break;
          case 'deposit_rejected':
            _handleDepositRejected(data['data']);
            break;
          case 'payment_processed':
            _handlePaymentProcessed(data['data']);
            break;
          case 'refund_processed':
            _handleRefundProcessed(data['data']);
            break;
        }
      }
    });
  }

  void _handleDepositApproved(Map<String, dynamic>? data) {
    if (data != null) {
      print('✅ Deposit approved: ${data['amount']}');
      // Reload both balance and transactions
      loadWalletData();
    }
  }

  void _handleDepositRejected(Map<String, dynamic>? data) {
    if (data != null) {
      print('❌ Deposit rejected: ${data['amount']}');
      // Reload transactions to show updated status
      loadTransactions(page: 1);
    }
  }

  void _handlePaymentProcessed(Map<String, dynamic>? data) {
    if (data != null) {
      print('💳 Payment processed: ${data['amount']}');
      // Reload both balance and transactions
      loadWalletData();
    }
  }

  void _handleRefundProcessed(Map<String, dynamic>? data) {
    if (data != null) {
      print('💸 Refund processed: ${data['amount']}');
      // Reload both balance and transactions
      loadWalletData();
    }
  }

  Future<void> loadWalletData() async {
    // Prevent concurrent loading
    if (_loadingFuture != null) {
      return _loadingFuture!;
    }
    
    _loadingFuture = _performLoad();
    try {
      await _loadingFuture!;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<void> _performLoad() async {
    print('🔄 WalletProvider: Starting to load wallet data...');
    _setLoading(true);
    _clearError();

    try {
      print('📡 WalletProvider: Calling API services...');
      
      // Load balance first
      print('💰 Loading wallet balance...');
      _balance = await _apiService.getWalletBalance();
      print('✅ Balance loaded: $_balance');
      
      // Then load transactions
      print('📋 Loading wallet transactions...');
      final transactionData = await _apiService.getWalletTransactions();
      print('📊 Raw transaction data type: ${transactionData.runtimeType}');
      print('📊 Raw transaction data: ${transactionData.toString().substring(0, 200)}...');
      
      _transactions = transactionData
          .map((json) {
            try {
              print('🔍 Parsing transaction: ${json.toString().substring(0, 100)}...');
              return WalletTransaction.fromJson(json);
            } catch (e) {
              print('❌ Error parsing transaction: $e');
              print('📄 Problematic JSON: $json');
              rethrow;
            }
          })
          .toList();
      
      print('✅ WalletProvider: Loaded successfully');
      print('💰 Balance: $_balance');
      print('📋 Transactions: ${_transactions.length}');
    } catch (e) {
      print('❌ WalletProvider: Error loading data: $e');
      print('📄 Error details: ${e.toString()}');
      _setError(e.toString());
    }

    _setLoading(false);
  }

  Future<void> loadTransactions({int page = 1, int pageSize = 20}) async {
    try {
      final transactionData = await _apiService.getWalletTransactions(
        page: page,
        pageSize: pageSize,
      );
      
      final newTransactions = transactionData
          .map((json) => WalletTransaction.fromJson(json))
          .toList();

      if (page == 1) {
        _transactions = newTransactions;
      } else {
        _transactions.addAll(newTransactions);
      }
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> createDepositRequest({
    required double amount,
    required String description,
    String? proofImageUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.createDepositRequest(
        amount: amount,
        description: description,
        proofImageUrl: proofImageUrl,
      );

      // Reload transactions to show the new pending request
      await loadTransactions();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> refreshBalance() async {
    try {
      print('🔄 Refreshing wallet balance...');
      _balance = await _apiService.getWalletBalance();
      print('💰 New balance: $_balance');
      
      // Also reload transactions to stay in sync
      await loadTransactions(page: 1);
      
      notifyListeners();
    } catch (e) {
      print('❌ Error refreshing balance: $e');
      _setError(e.toString());
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
  String get formattedBalance {
    return '${_balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ';
  }

  List<WalletTransaction> get recentTransactions {
    return _transactions.take(5).toList();
  }

  double get totalDeposited {
    return _transactions
        .where((t) => t.type == 'Deposit' && t.status == 'Completed')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalSpent {
    return _transactions
        .where((t) => t.type == 'Payment' && t.status == 'Completed')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  int get pendingTransactionsCount {
    return _transactions.where((t) => t.status == 'Pending').length;
  }
}