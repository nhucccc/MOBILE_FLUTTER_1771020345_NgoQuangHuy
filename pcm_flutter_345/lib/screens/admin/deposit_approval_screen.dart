import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_card.dart';

class DepositApprovalScreen extends StatefulWidget {
  const DepositApprovalScreen({super.key});

  @override
  State<DepositApprovalScreen> createState() => _DepositApprovalScreenState();
}

class _DepositApprovalScreenState extends State<DepositApprovalScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _pendingDeposits = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadPendingDeposits();
  }

  Future<void> _loadPendingDeposits({int page = 1}) async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.get('/admin/pending-deposits?page=$page&pageSize=20');
      setState(() {
        _pendingDeposits = List<Map<String, dynamic>>.from(response['deposits']);
        _currentPage = page;
        _totalPages = response['totalPages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _approveDeposit(int transactionId, String memberName, double amount) async {
    final adminNotes = await _showNotesDialog('Duyệt nạp tiền', 'Ghi chú (tùy chọn):');
    if (adminNotes == null) return;

    try {
      await _apiService.post('/admin/deposits/$transactionId/approve', {
        'adminNotes': adminNotes,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã duyệt nạp tiền ${amount.toStringAsFixed(0)}đ cho $memberName'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingDeposits(page: _currentPage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectDeposit(int transactionId, String memberName, double amount) async {
    final reason = await _showNotesDialog('Từ chối nạp tiền', 'Lý do từ chối:', required: true);
    if (reason == null || reason.isEmpty) return;

    try {
      await _apiService.post('/admin/deposits/$transactionId/reject', {
        'reason': reason,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Đã từ chối nạp tiền ${amount.toStringAsFixed(0)}đ cho $memberName'),
            backgroundColor: Colors.red,
          ),
        );
        _loadPendingDeposits(page: _currentPage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _showNotesDialog(String title, String hint, {bool required = false}) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (required && controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do')),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt nạp tiền'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _loadPendingDeposits(page: _currentPage),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingDeposits.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(child: _buildDepositList()),
                    if (_totalPages > 1) _buildPagination(),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không có yêu cầu nạp tiền nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tất cả yêu cầu đã được xử lý',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, kBottomNavigationBarHeight + 32),
      itemCount: _pendingDeposits.length,
      itemBuilder: (context, index) {
        final deposit = _pendingDeposits[index];
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deposit['memberName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'ID: ${deposit['memberId']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(deposit['amount'] as num).toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (deposit['description'] != null && deposit['description'].isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mô tả:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deposit['description'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(deposit['createdDate']),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (deposit['proofImageUrl'] != null)
                    TextButton.icon(
                      onPressed: () => _showProofImage(deposit['proofImageUrl']),
                      icon: const Icon(Icons.image, size: 16),
                      label: const Text('Xem ảnh'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectDeposit(
                        deposit['id'],
                        deposit['memberName'],
                        (deposit['amount'] as num).toDouble(),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveDeposit(
                        deposit['id'],
                        deposit['memberName'],
                        (deposit['amount'] as num).toDouble(),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Duyệt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 1
                ? () => _loadPendingDeposits(page: _currentPage - 1)
                : null,
            child: const Text('Trước'),
          ),
          Text('Trang $_currentPage/$_totalPages'),
          ElevatedButton(
            onPressed: _currentPage < _totalPages
                ? () => _loadPendingDeposits(page: _currentPage + 1)
                : null,
            child: const Text('Sau'),
          ),
        ],
      ),
    );
  }

  void _showProofImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Ảnh chứng minh'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Image.network(
                imageUrl,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text('Không thể tải ảnh'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}