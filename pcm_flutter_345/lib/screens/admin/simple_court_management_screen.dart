import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SimpleCourtManagementScreen extends StatefulWidget {
  const SimpleCourtManagementScreen({super.key});

  @override
  State<SimpleCourtManagementScreen> createState() => _SimpleCourtManagementScreenState();
}

class _SimpleCourtManagementScreenState extends State<SimpleCourtManagementScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _courts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.get('/test/test-admin-courts');
      print('Courts API response: $response');
      
      if (response is Map<String, dynamic> && response['data'] != null) {
        setState(() {
          _courts = List<Map<String, dynamic>>.from(response['data']);
          _isLoading = false;
        });
        print('Courts loaded: ${_courts.length}');
      } else {
        setState(() {
          _courts = [];
          _isLoading = false;
        });
        print('No courts data found');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading courts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sân'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courts.isEmpty
              ? const Center(child: Text('Chưa có sân nào'))
              : ListView.builder(
                  itemCount: _courts.length,
                  itemBuilder: (context, index) {
                    final court = _courts[index];
                    return ListTile(
                      title: Text(court['name'] ?? 'Unknown'),
                      subtitle: Text('${court['pricePerHour']}đ/giờ'),
                      trailing: Text(court['isActive'] ? 'Hoạt động' : 'Vô hiệu'),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCourtDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateCourtDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo sân mới'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên sân *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên sân';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá thuê (đ/giờ) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập giá thuê';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Giá thuê phải là số dương';
                  }
                  return null;
                },
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _createCourt(
                  nameController.text.trim(),
                  descriptionController.text.trim(),
                  double.parse(priceController.text),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tạo sân'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCourt(String name, String description, double price) async {
    try {
      final response = await _apiService.post('/test/test-create-court', {
        'name': name,
        'description': description,
        'pricePerHour': price,
      });

      if (response is Map<String, dynamic> && response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã tạo sân mới thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Reload courts list to show new court
        await _loadCourts();
      } else {
        throw Exception(response['message'] ?? 'Lỗi không xác định');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo sân: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}