import 'package:flutter/material.dart';
import '../../../core/models/wallet_model.dart';
import '../../../core/services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _apiService;

  WalletBalance? _walletBalance;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  WalletProvider(this._apiService);

  // Getters
  WalletBalance? get walletBalance => _walletBalance;
  double? get balance => _walletBalance?.balance;
  String? get tier => _walletBalance?.tier;
  double? get totalSpent => _walletBalance?.totalSpent;
  List<WalletTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWalletBalance() async {
    _setLoading(true);
    try {
      final response = await _apiService.get<Map<String, dynamic>>('/api/wallet/balance');
      _walletBalance = WalletBalance.fromJson(response.data!);
      _clearError();
    } catch (e) {
      _setError('Lỗi tải số dư ví: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTransactions({int page = 1, int pageSize = 20}) async {
    if (page == 1) _setLoading(true);
    
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/api/wallet/transactions',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      
      final newTransactions = (response.data as List)
          .map((json) => WalletTransaction.fromJson(json))
          .toList();
      
      if (page == 1) {
        _transactions = newTransactions;
      } else {
        _transactions.addAll(newTransactions);
      }
      
      _clearError();
    } catch (e) {
      _setError('Lỗi tải lịch sử giao dịch: ${e.toString()}');
    } finally {
      if (page == 1) _setLoading(false);
    }
  }

  Future<bool> createDepositRequest(double amount, String? description, String? proofImageUrl) async {
    _setLoading(true);
    try {
      final request = DepositRequest(
        amount: amount,
        description: description,
        proofImageUrl: proofImageUrl,
      );
      
      await _apiService.post<Map<String, dynamic>>(
        '/api/wallet/deposit',
        data: request.toJson(),
      );
      
      // Reload transactions to show the new deposit request
      await loadTransactions();
      _clearError();
      return true;
    } catch (e) {
      _setError('Lỗi tạo yêu cầu nạp tiền: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void updateBalanceFromSignalR(double newBalance) {
    if (_walletBalance != null) {
      _walletBalance = WalletBalance(
        balance: newBalance,
        tier: _walletBalance!.tier,
        totalSpent: _walletBalance!.totalSpent,
        recentTransactions: _walletBalance!.recentTransactions,
      );
      notifyListeners();
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
}