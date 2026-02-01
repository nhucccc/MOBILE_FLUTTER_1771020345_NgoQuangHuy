import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';

class TournamentManagementScreen extends StatefulWidget {
  const TournamentManagementScreen({Key? key}) : super(key: key);

  @override
  State<TournamentManagementScreen> createState() => _TournamentManagementScreenState();
}

class _TournamentManagementScreenState extends State<TournamentManagementScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _tournaments = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedStatus;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;

  final List<String> _statuses = ['Open', 'Registering', 'InProgress', 'Completed', 'Cancelled'];
  final List<String> _formats = ['Knockout', 'RoundRobin', 'Hybrid'];

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'pageSize': _pageSize.toString(),
      };
      
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;
      if (_selectedStatus != null) queryParams['status'] = _selectedStatus!;

      final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      final response = await _apiService.get('/test/test-tournaments?$queryString');
      
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _tournaments = List<dynamic>.from(response['data']);
          _totalPages = 1; // For simplicity, we'll use single page for test
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Không thể tải danh sách giải đấu';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showTournamentDialog({Map<String, dynamic>? tournament}) async {
    final nameController = TextEditingController(text: tournament?['name'] ?? '');
    final descriptionController = TextEditingController(text: tournament?['description'] ?? '');
    final entryFeeController = TextEditingController(text: tournament?['entryFee']?.toString() ?? '0');
    final prizePoolController = TextEditingController(text: tournament?['prizePool']?.toString() ?? '0');
    final maxParticipantsController = TextEditingController(text: tournament?['maxParticipants']?.toString() ?? '32');
    
    DateTime startDate = tournament != null 
        ? DateTime.parse(tournament['startDate']) 
        : DateTime.now().add(const Duration(days: 7));
    DateTime endDate = tournament != null 
        ? DateTime.parse(tournament['endDate']) 
        : DateTime.now().add(const Duration(days: 9));
    
    String selectedFormat = tournament?['format'] ?? 'Knockout';
    String selectedStatus = tournament?['status'] ?? 'Open';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tournament == null ? 'Tạo giải đấu mới' : 'Chỉnh sửa giải đấu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên giải đấu *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              startDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ngày bắt đầu *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('${startDate.day}/${startDate.month}/${startDate.year}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              endDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ngày kết thúc *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('${endDate.day}/${endDate.month}/${endDate.year}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedFormat,
                  decoration: const InputDecoration(
                    labelText: 'Định dạng',
                    border: OutlineInputBorder(),
                  ),
                  items: _formats.map((format) => DropdownMenuItem(
                    value: format,
                    child: Text(format),
                  )).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedFormat = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: entryFeeController,
                        decoration: const InputDecoration(
                          labelText: 'Phí tham gia (đ)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: prizePoolController,
                        decoration: const InputDecoration(
                          labelText: 'Giải thưởng (đ)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: maxParticipantsController,
                  decoration: const InputDecoration(
                    labelText: 'Số lượng tối đa',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (tournament != null) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                    ),
                    items: _statuses.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(_getStatusText(status)),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên giải đấu')),
                  );
                  return;
                }

                try {
                  final data = {
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'startDate': startDate.toIso8601String(),
                    'endDate': endDate.toIso8601String(),
                    'format': selectedFormat,
                    'entryFee': double.parse(entryFeeController.text),
                    'prizePool': double.parse(prizePoolController.text),
                    'maxParticipants': int.parse(maxParticipantsController.text),
                  };

                  if (tournament != null) {
                    data['status'] = selectedStatus;
                  }

                  if (tournament == null) {
                    final newTournamentResponse = await _apiService.post('/test/test-tournaments', data);
                    if (newTournamentResponse['success'] == true) {
                      // Add the new tournament to the list immediately
                      final newTournament = newTournamentResponse['data'];
                      setState(() {
                        _tournaments.insert(0, newTournament); // Add to beginning of list
                      });
                    }
                  } else {
                    await _apiService.put('/test/test-tournaments/${tournament['id']}', data);
                    // Reload tournaments to get updated data
                    _loadTournaments();
                  }

                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: Text(tournament == null ? 'Tạo' : 'Cập nhật', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && tournament != null) {
      // Only reload if we're editing existing tournament
      _loadTournaments();
    }
  }

  Future<void> _cancelTournament(Map<String, dynamic> tournament) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hủy giải đấu "${tournament['name']}"'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Lý do hủy *',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do hủy')),
                );
                return;
              }

              try {
                await _apiService.post('/test/test-tournaments/${tournament['id']}/cancel', {
                  'reason': reasonController.text,
                });
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy giải đấu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy giải đấu thành công')),
      );
      _loadTournaments();
    }
  }

  Future<void> _deleteTournament(Map<String, dynamic> tournament) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa giải đấu "${tournament['name']}"?\n\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/tournament/${tournament['id']}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa giải đấu thành công')),
        );
        _loadTournaments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa giải đấu: $e')),
        );
      }
    }
  }

  Widget _buildTournamentCard(Map<String, dynamic> tournament) {
    return SimpleCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 30,
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
                            tournament['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(tournament['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(tournament['status']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (tournament['description'] != null && tournament['description'].isNotEmpty)
                      Text(
                        tournament['description'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                  Icons.calendar_today,
                  'Bắt đầu',
                  _formatDate(tournament['startDate']),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.people,
                  'Tham gia',
                  '${tournament['participantCount']}/${tournament['maxParticipants']}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.category,
                  'Định dạng',
                  tournament['format'] ?? 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.attach_money,
                  'Phí tham gia',
                  tournament['entryFee'] > 0 ? '${tournament['entryFee']?.toStringAsFixed(0) ?? '0'}đ' : 'Miễn phí',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.emoji_events,
                  'Giải thưởng',
                  '${tournament['prizePool']?.toStringAsFixed(0) ?? '0'}đ',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.schedule,
                  'Tạo lúc',
                  _formatDate(tournament['createdDate']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTournamentDialog(tournament: tournament),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Sửa'),
                ),
              ),
              const SizedBox(width: 8),
              if (tournament['status'] != 'Cancelled' && tournament['status'] != 'Completed') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _cancelTournament(tournament),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Hủy'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                onPressed: () => _deleteTournament(tournament),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.blue;
      case 'Registering':
        return Colors.green;
      case 'InProgress':
        return Colors.orange;
      case 'Completed':
        return Colors.purple;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Open':
        return 'Mở đăng ký';
      case 'Registering':
        return 'Đang đăng ký';
      case 'InProgress':
        return 'Đang diễn ra';
      case 'Completed':
        return 'Đã kết thúc';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý giải đấu'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTournaments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm giải đấu...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 1;
                    });
                    _loadTournaments();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả')),
                    ..._statuses.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(_getStatusText(status)),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                      _currentPage = 1;
                    });
                    _loadTournaments();
                  },
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadTournaments,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _tournaments.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('Chưa có giải đấu nào'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _tournaments.length,
                            itemBuilder: (context, index) {
                              return _buildTournamentCard(_tournaments[index]);
                            },
                          ),
          ),
          
          // Pagination
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1 ? () {
                      setState(() {
                        _currentPage--;
                      });
                      _loadTournaments();
                    } : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('$_currentPage / $_totalPages'),
                  IconButton(
                    onPressed: _currentPage < _totalPages ? () {
                      setState(() {
                        _currentPage++;
                      });
                      _loadTournaments();
                    } : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTournamentDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}