import 'package:flutter/material.dart';
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

  double get balance => _balance;
  List<WalletTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  WalletProvider() {
    _setupSignalRListeners();
  }

  void _setupSignalRListeners() {
    _signalRService.onWalletUpdated((newBalance) {
      _balance = newBalance;
      notifyListeners();
    });
  }

  Future<void> loadWalletData() async {
    _setLoading(true);
    _clearError();

    try {
      // Load balance and transactions in parallel
      final results = await Future.wait([
        _apiService.getWalletBalance(),
        _apiService.getWalletTransactions(),
      ]);

      _balance = results[0] as double;
      final transactionData = results[1] as List<Map<String, dynamic>>;
      _transactions = transactionData
          .map((json) => WalletTransaction.fromJson(json))
          .toList();
    } catch (e) {
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
      _balance = await _apiService.getWalletBalance();
      notifyListeners();
    } catch (e) {
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