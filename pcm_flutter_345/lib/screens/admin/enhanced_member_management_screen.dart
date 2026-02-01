import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_card.dart';

class EnhancedMemberManagementScreen extends StatefulWidget {
  const EnhancedMemberManagementScreen({super.key});

  @override
  State<EnhancedMemberManagementScreen> createState() => _EnhancedMemberManagementScreenState();
}

class _EnhancedMemberManagementScreenState extends State<EnhancedMemberManagementScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers({int page = 1, String? search}) async {
    setState(() => _isLoading = true);
    
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': 20,
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      
      final response = await _apiService.get('/test/test-admin-members?$queryString');
      print('Members API response: $response');
      
      if (response is Map<String, dynamic> && response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _members = List<Map<String, dynamic>>.from(data['members']);
          _currentPage = data['currentPage'] ?? page;
          _totalPages = data['totalPages'] ?? 1;
          _isLoading = false;
        });
        print('Members loaded: ${_members.length}');
      } else {
        setState(() {
          _members = [];
          _currentPage = page;
          _totalPages = 1;
          _isLoading = false;
        });
        print('No members data found');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _updateMemberStatus(int memberId, String memberName, bool currentStatus) async {
    final newStatus = !currentStatus;
    final action = newStatus ? 'kích hoạt' : 'vô hiệu hóa';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận $action'),
        content: Text('Bạn có chắc muốn $action thành viên $memberName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.red,
            ),
            child: Text(newStatus ? 'Kích hoạt' : 'Vô hiệu hóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiService.put('/test/test-update-member-status/$memberId', {
        'isActive': newStatus,
      });

      if (response is Map<String, dynamic> && response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã $action thành viên $memberName'),
              backgroundColor: Colors.green,
            ),
          );
          _loadMembers(page: _currentPage, search: _searchQuery);
        }
      } else {
        throw Exception(response['message'] ?? 'Lỗi không xác định');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateMemberTier(int memberId, String memberName, String currentTier) async {
    final tiers = ['Standard', 'Silver', 'Gold', 'Diamond'];
    final tierNames = ['Đồng', 'Bạc', 'Vàng', 'Kim Cương'];
    
    final selectedTier = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật tier cho $memberName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: tiers.asMap().entries.map((entry) {
            final tier = entry.value;
            final tierName = tierNames[entry.key];
            return RadioListTile<String>(
              title: Text(tierName),
              value: tier,
              groupValue: currentTier,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (selectedTier == null || selectedTier == currentTier) return;

    try {
      final response = await _apiService.put('/test/test-update-member-tier/$memberId', {
        'tier': selectedTier,
      });

      if (response is Map<String, dynamic> && response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã cập nhật tier cho $memberName'),
              backgroundColor: Colors.green,
            ),
          );
          _loadMembers(page: _currentPage, search: _searchQuery);
        }
      } else {
        throw Exception(response['message'] ?? 'Lỗi không xác định');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _adjustMemberWallet(int memberId, String memberName, double currentBalance) async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'add';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Điều chỉnh ví cho $memberName'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Số dư hiện tại: ${currentBalance.toStringAsFixed(0)}đ'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Thêm tiền'),
                        value: 'add',
                        groupValue: selectedType,
                        onChanged: (value) {
                          setDialogState(() => selectedType = value!);
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Trừ tiền'),
                        value: 'subtract',
                        groupValue: selectedType,
                        onChanged: (value) {
                          setDialogState(() => selectedType = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền *',
                    border: OutlineInputBorder(),
                    suffixText: 'đ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số tiền';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Số tiền phải là số dương';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, {
                    'amount': double.parse(amountController.text),
                    'type': selectedType,
                    'notes': notesController.text.trim(),
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedType == 'add' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(selectedType == 'add' ? 'Thêm tiền' : 'Trừ tiền'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      final response = await _apiService.post('/test/test-adjust-member-wallet/$memberId', {
        'amount': result['amount'],
        'type': result['type'],
        'notes': result['notes'],
      });

      if (response is Map<String, dynamic> && response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${response['message']}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadMembers(page: _currentPage, search: _searchQuery);
        }
      } else {
        throw Exception(response['message'] ?? 'Lỗi không xác định');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showCreateMemberDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'Member';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo thành viên mới'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu *',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Member', child: Text('Thành viên')),
                      DropdownMenuItem(value: 'Admin', child: Text('Quản trị viên')),
                      DropdownMenuItem(value: 'Referee', child: Text('Trọng tài')),
                      DropdownMenuItem(value: 'Treasurer', child: Text('Thủ quỹ')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedRole = value!);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, {
                    'fullName': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phoneNumber': phoneController.text.trim(),
                    'password': passwordController.text,
                    'role': selectedRole,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tạo thành viên'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      final response = await _apiService.post('/test/test-create-member', result);

      if (response is Map<String, dynamic> && response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${response['message']}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadMembers(page: _currentPage, search: _searchQuery);
        }
      } else {
        throw Exception(response['message'] ?? 'Lỗi không xác định');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadMembers(page: 1, search: _searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thành viên'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _loadMembers(page: _currentPage, search: _searchQuery),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên hoặc email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => _onSearchChanged(),
            ),
          ),
          
          // Member list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                    ? _buildEmptyState()
                    : _buildMemberList(),
          ),
          
          // Pagination
          if (_totalPages > 1) _buildPagination(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMemberDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'Không tìm thấy thành viên' : 'Chưa có thành viên nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showCreateMemberDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Tạo thành viên đầu tiên'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, kBottomNavigationBarHeight + 32),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getTierColor(member['tier']).withOpacity(0.1),
                    child: Text(
                      member['fullName'][0].toUpperCase(),
                      style: TextStyle(
                        color: _getTierColor(member['tier']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                member['fullName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: member['isActive'] ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                member['isActive'] ? 'Hoạt động' : 'Vô hiệu',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member['email'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Tier',
                      _getTierDisplayName(member['tier']),
                      _getTierColor(member['tier']),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Số dư',
                      '${(member['walletBalance'] as num).toStringAsFixed(0)}đ',
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Đã chi',
                      '${(member['totalSpent'] as num).toStringAsFixed(0)}đ',
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tham gia: ${_formatDate(member['joinDate'])}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Role: ${member['role']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateMemberTier(
                        member['id'],
                        member['fullName'],
                        member['tier'],
                      ),
                      icon: const Icon(Icons.star_outline),
                      label: const Text('Đổi tier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _adjustMemberWallet(
                        member['id'],
                        member['fullName'],
                        (member['walletBalance'] as num).toDouble(),
                      ),
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('Điều chỉnh ví'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateMemberStatus(
                        member['id'],
                        member['fullName'],
                        member['isActive'],
                      ),
                      icon: Icon(member['isActive'] ? Icons.block : Icons.check),
                      label: Text(member['isActive'] ? 'Vô hiệu' : 'Kích hoạt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: member['isActive'] ? Colors.red : Colors.green,
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

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
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
                ? () => _loadMembers(page: _currentPage - 1, search: _searchQuery)
                : null,
            child: const Text('Trước'),
          ),
          Text('Trang $_currentPage/$_totalPages'),
          ElevatedButton(
            onPressed: _currentPage < _totalPages
                ? () => _loadMembers(page: _currentPage + 1, search: _searchQuery)
                : null,
            child: const Text('Sau'),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Standard':
        return const Color(0xFFCD7F32);
      case 'Silver':
        return const Color(0xFFC0C0C0);
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Diamond':
        return const Color(0xFFB9F2FF);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  String _getTierDisplayName(String tier) {
    switch (tier) {
      case 'Standard':
        return 'Đồng';
      case 'Silver':
        return 'Bạc';
      case 'Gold':
        return 'Vàng';
      case 'Diamond':
        return 'Kim Cương';
      default:
        return 'Đồng';
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }
}