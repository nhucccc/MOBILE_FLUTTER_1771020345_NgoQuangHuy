import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_card.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  Map<String, dynamic> _settings = {};
  
  // Controllers for settings
  final _bookingAdvanceDaysController = TextEditingController();
  final _cancellationHoursController = TextEditingController();
  final _reminderHoursController = TextEditingController();
  final _maxRecurringBookingsController = TextEditingController();
  bool _autoCleanupEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _bookingAdvanceDaysController.dispose();
    _cancellationHoursController.dispose();
    _reminderHoursController.dispose();
    _maxRecurringBookingsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await _apiService.get('/admin/system-settings');
      setState(() {
        _settings = settings;
        _bookingAdvanceDaysController.text = settings['bookingAdvanceDays'].toString();
        _cancellationHoursController.text = settings['cancellationHours'].toString();
        _reminderHoursController.text = settings['reminderHours'].toString();
        _maxRecurringBookingsController.text = settings['maxRecurringBookings'].toString();
        _autoCleanupEnabled = settings['autoCleanupEnabled'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải cài đặt: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    // Validate inputs
    final bookingAdvanceDays = int.tryParse(_bookingAdvanceDaysController.text);
    final cancellationHours = int.tryParse(_cancellationHoursController.text);
    final reminderHours = int.tryParse(_reminderHoursController.text);
    final maxRecurringBookings = int.tryParse(_maxRecurringBookingsController.text);

    if (bookingAdvanceDays == null || bookingAdvanceDays < 1) {
      _showError('Số ngày đặt trước phải là số dương');
      return;
    }

    if (cancellationHours == null || cancellationHours < 1) {
      _showError('Số giờ hủy trước phải là số dương');
      return;
    }

    if (reminderHours == null || reminderHours < 1) {
      _showError('Số giờ nhắc nhở phải là số dương');
      return;
    }

    if (maxRecurringBookings == null || maxRecurringBookings < 1) {
      _showError('Số booking định kỳ tối đa phải là số dương');
      return;
    }

    try {
      await _apiService.put('/admin/system-settings', {
        'bookingAdvanceDays': bookingAdvanceDays,
        'cancellationHours': cancellationHours,
        'autoCleanupEnabled': _autoCleanupEnabled,
        'reminderHours': reminderHours,
        'maxRecurringBookings': maxRecurringBookings,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu cài đặt hệ thống'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadSettings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, kBottomNavigationBarHeight + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBookingSettings(),
                  const SizedBox(height: 24),
                  _buildSystemSettings(),
                  const SizedBox(height: 24),
                  _buildNotificationSettings(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildBookingSettings() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                'Cài đặt đặt sân',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bookingAdvanceDaysController,
            decoration: const InputDecoration(
              labelText: 'Số ngày đặt trước tối đa',
              helperText: 'Thành viên có thể đặt sân trước tối đa bao nhiêu ngày',
              border: OutlineInputBorder(),
              suffixText: 'ngày',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cancellationHoursController,
            decoration: const InputDecoration(
              labelText: 'Thời gian hủy tối thiểu',
              helperText: 'Phải hủy trước ít nhất bao nhiêu giờ',
              border: OutlineInputBorder(),
              suffixText: 'giờ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _maxRecurringBookingsController,
            decoration: const InputDecoration(
              labelText: 'Số booking định kỳ tối đa',
              helperText: 'Một lần tạo tối đa bao nhiêu booking định kỳ',
              border: OutlineInputBorder(),
              suffixText: 'booking',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettings() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text(
                'Cài đặt hệ thống',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Tự động dọn dẹp'),
            subtitle: const Text('Tự động hủy booking chưa thanh toán và gửi nhắc nhở'),
            value: _autoCleanupEnabled,
            onChanged: (value) {
              setState(() {
                _autoCleanupEnabled = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.backup, color: Colors.blue[600]),
            title: const Text('Sao lưu dữ liệu'),
            subtitle: const Text('Tạo bản sao lưu dữ liệu hệ thống'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showBackupDialog,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.restore, color: Colors.orange[600]),
            title: const Text('Khôi phục dữ liệu'),
            subtitle: const Text('Khôi phục từ bản sao lưu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showRestoreDialog,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications, color: Colors.orange[600]),
              const SizedBox(width: 8),
              const Text(
                'Cài đặt thông báo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reminderHoursController,
            decoration: const InputDecoration(
              labelText: 'Thời gian nhắc nhở',
              helperText: 'Gửi nhắc nhở trước bao nhiêu giờ',
              border: OutlineInputBorder(),
              suffixText: 'giờ',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveSettings,
        icon: const Icon(Icons.save),
        label: const Text('Lưu cài đặt'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sao lưu dữ liệu'),
        content: const Text('Bạn có muốn tạo bản sao lưu dữ liệu hệ thống không?\n\nQuá trình này có thể mất vài phút.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBackup();
            },
            child: const Text('Sao lưu'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục dữ liệu'),
        content: const Text('⚠️ CẢNH BÁO: Khôi phục dữ liệu sẽ ghi đè lên tất cả dữ liệu hiện tại.\n\nBạn có chắc chắn muốn tiếp tục?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performRestore();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang sao lưu dữ liệu...'),
          ],
        ),
      ),
    );

    // Simulate backup process
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Sao lưu dữ liệu thành công'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _performRestore() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang khôi phục dữ liệu...'),
          ],
        ),
      ),
    );

    // Simulate restore process
    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Khôi phục dữ liệu thành công'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}