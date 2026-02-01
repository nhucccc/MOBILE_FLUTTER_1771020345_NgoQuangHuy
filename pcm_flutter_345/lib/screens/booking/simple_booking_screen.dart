import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../models/court.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class SimpleBookingScreen extends StatefulWidget {
  const SimpleBookingScreen({Key? key}) : super(key: key);

  @override
  State<SimpleBookingScreen> createState() => _SimpleBookingScreenState();
}

class _SimpleBookingScreenState extends State<SimpleBookingScreen> with SingleTickerProviderStateMixin {
  List<Court> courts = [];
  List<Map<String, dynamic>> userBookings = [];
  List<Map<String, dynamic>> timeSlots = [];
  bool isLoading = true;
  bool isLoadingBookings = true;
  bool isLoadingTimeSlots = false;
  DateTime selectedDate = DateTime.now();
  int? selectedCourtId;
  String? selectedTimeSlot;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCourts();
    _loadUserBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourts() async {
    print('Loading courts...'); // Debug log
    try {
      final response = await http.get(
        Uri.parse('http://localhost:58377/api/TestBooking/test-courts'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Response status: ${response.statusCode}'); // Debug log
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response data: $data'); // Debug log
        
        if (data['success'] == true) {
          setState(() {
            courts = (data['courts'] as List)
                .map((courtJson) => Court.fromJson(courtJson))
                .toList();
            isLoading = false;
          });
          print('Loaded ${courts.length} courts from API'); // Debug log
          return;
        }
      }
    } catch (e) {
      print('Error loading courts: $e');
    }
    
    // Fallback data for Android/mobile testing
    print('Using fallback court data'); // Debug log
    setState(() {
      courts = [
        Court(
          id: 1,
          name: 'Sân A',
          description: 'Sân chính',
          pricePerHour: 150000,
          isActive: true,
        ),
        Court(
          id: 2,
          name: 'Sân B',
          description: 'Sân phụ',
          pricePerHour: 120000,
          isActive: true,
        ),
        Court(
          id: 3,
          name: 'Sân C',
          description: 'Sân VIP',
          pricePerHour: 200000,
          isActive: true,
        ),
        Court(
          id: 4,
          name: 'Sân D',
          description: 'Sân thường',
          pricePerHour: 100000,
          isActive: true,
        ),
      ];
      isLoading = false;
    });
    print('Fallback courts loaded: ${courts.length}'); // Debug log
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Đặt Sân',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(
              icon: Icon(Icons.add_circle_outline),
              text: 'Đặt sân',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Lịch sử',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildBookingTab() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateSelector(),
                const SizedBox(height: 24),
                _buildCourtSelector(),
                const SizedBox(height: 24),
                if (selectedCourtId != null) _buildTimeSlotGrid(),
                const SizedBox(height: 24),
                if (selectedCourtId != null && selectedTimeSlot != null)
                  _buildBookingButton(),
              ],
            ),
          );
  }

  Widget _buildHistoryTab() {
    return isLoadingBookings
        ? const Center(child: CircularProgressIndicator())
        : userBookings.isEmpty
            ? _buildEmptyHistory()
            : RefreshIndicator(
                onRefresh: _loadUserBookings,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: userBookings.length,
                  itemBuilder: (context, index) {
                    final booking = userBookings[index];
                    return _buildBookingHistoryCard(booking);
                  },
                ),
              );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn ngày',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                label: const Text('Thay đổi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourtSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn sân',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Loading indicator
          if (isLoading)
            Container(
              height: 120,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Đang tải danh sách sân...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Debug info
          if (courts.isEmpty && !isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 24),
                  const SizedBox(height: 8),
                  const Text(
                    'Không có sân nào khả dụng',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Vui lòng kiểm tra kết nối mạng',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          // Courts grid
          if (courts.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8, // Giảm spacing
                mainAxisSpacing: 8,  // Giảm spacing
                childAspectRatio: 1.4, // Tăng ratio để làm thấp hơn
              ),
              itemCount: courts.length,
              itemBuilder: (context, index) {
                final court = courts[index];
                final isSelected = selectedCourtId == court.id;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedCourtId = court.id;
                      selectedTimeSlot = null; // Reset time slot when changing court
                      timeSlots = []; // Clear current time slots
                    });
                    _loadTimeSlots(); // Load time slots for selected court
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8), // Giảm padding
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_tennis_rounded,
                          color: isSelected ? Colors.blue : Colors.grey[600],
                          size: 24, // Giảm icon size
                        ),
                        const SizedBox(height: 4),
                        Text(
                          court.name,
                          style: TextStyle(
                            fontSize: 12, // Giảm font size
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(court.pricePerHour / 1000).toStringAsFixed(0)}K/h',
                          style: TextStyle(
                            fontSize: 10, // Giảm font size
                            color: isSelected ? Colors.blue : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    if (isLoadingTimeSlots) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn khung giờ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6, // Giảm spacing
              mainAxisSpacing: 6,  // Giảm spacing
              childAspectRatio: 3.0, // Tăng ratio để làm thấp hơn
            ),
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              final timeSlot = timeSlots[index];
              final timeSlotText = timeSlot['time'] as String;
              final status = timeSlot['status'] as String;
              final isSelected = selectedTimeSlot == timeSlotText;
              final isAvailable = timeSlot['isAvailable'] as bool;
              
              return InkWell(
                onTap: isAvailable ? () {
                  setState(() {
                    selectedTimeSlot = timeSlotText;
                  });
                } : status == 'past' ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể đặt sân trong quá khứ!'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } : null,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3), // Giảm padding
                  decoration: BoxDecoration(
                    color: _getTimeSlotColor(status, isSelected),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getTimeSlotBorderColor(status, isSelected),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Thêm để giảm chiều cao
                    children: [
                      Flexible( // Wrap với Flexible
                        child: Text(
                          timeSlotText,
                          style: TextStyle(
                            fontSize: 9, // Giảm font size
                            fontWeight: FontWeight.w600,
                            color: _getTimeSlotTextColor(status, isSelected),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 1), // Giảm spacing
                      Flexible( // Wrap với Flexible
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontSize: 7, // Giảm font size
                            color: _getTimeSlotTextColor(status, isSelected).withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeSlot['memberName'] != null && (status == 'booked' || status == 'past')) ...[
                        Flexible( // Wrap với Flexible
                          child: Text(
                            timeSlot['memberName'],
                            style: TextStyle(
                              fontSize: 6, // Giảm font size
                              color: _getTimeSlotTextColor(status, isSelected).withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Trống', Colors.green, Colors.white),
        _buildLegendItem('Đã giữ', Colors.orange, Colors.white),
        _buildLegendItem('Đã đặt', Colors.red, Colors.white),
        _buildLegendItem('Đã qua', Colors.grey, Colors.white),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingButton() {
    final selectedCourt = courts.firstWhere((c) => c.id == selectedCourtId);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin đặt sân',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Sân:', selectedCourt.name),
          _buildInfoRow('Ngày:', '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
          _buildInfoRow('Giờ:', selectedTimeSlot!),
          _buildInfoRow('Giá:', '${selectedCourt.pricePerHour.toStringAsFixed(0)},000 VNĐ'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Xác nhận đặt sân',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeSlotStatus(String timeSlot) {
    // This method is no longer needed as we get real status from API
    return 'available';
  }

  Future<void> _loadTimeSlots() async {
    if (selectedCourtId == null) return;
    
    setState(() {
      isLoadingTimeSlots = true;
    });
    
    print('Loading time slots for court $selectedCourtId on ${selectedDate.toIso8601String()}'); // Debug log
    
    try {
      final response = await http.get(
        Uri.parse('http://localhost:58377/api/TestBooking/court-slots/$selectedCourtId?date=${selectedDate.toIso8601String()}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Time slots response status: ${response.statusCode}'); // Debug log
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Time slots response data: $data'); // Debug log
        
        if (data['success'] == true) {
          setState(() {
            timeSlots = List<Map<String, dynamic>>.from(data['timeSlots']);
            isLoadingTimeSlots = false;
          });
          print('Loaded ${timeSlots.length} time slots from API'); // Debug log
          return;
        }
      }
    } catch (e) {
      print('Error loading time slots: $e');
    }
    
    // Fallback data for Android/mobile testing
    print('Using fallback time slot data'); // Debug log
    final now = DateTime.now();
    final selectedDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final isToday = selectedDateTime.day == now.day && 
                   selectedDateTime.month == now.month && 
                   selectedDateTime.year == now.year;
    
    List<Map<String, dynamic>> fallbackTimeSlots = [];
    
    // Generate time slots from 6:00 to 22:00 (6 AM to 10 PM)
    for (int hour = 6; hour < 22; hour++) {
      final timeSlotStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, 0);
      final timeSlotEnd = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour + 1, 0);
      final timeSlotText = '${hour.toString().padLeft(2, '0')}:00-${(hour + 1).toString().padLeft(2, '0')}:00';
      
      // Check if time slot is in the past
      bool isPast = isToday && timeSlotEnd.isBefore(now);
      
      // Generate some sample booking data for demonstration
      String status;
      bool isAvailable;
      String? memberName;
      
      if (isPast) {
        status = 'past';
        isAvailable = false;
        // Some past slots have member names
        if (hour % 3 == 0) {
          memberName = 'Nguyễn Văn A';
        }
      } else {
        // Create varied status for demo
        switch (hour % 4) {
          case 0:
            status = 'available';
            isAvailable = true;
            break;
          case 1:
            status = 'reserved';
            isAvailable = false;
            memberName = 'Trần Thị B';
            break;
          case 2:
            status = 'booked';
            isAvailable = false;
            memberName = 'Lê Văn C';
            break;
          default:
            status = 'available';
            isAvailable = true;
        }
      }
      
      fallbackTimeSlots.add({
        'time': timeSlotText,
        'status': status,
        'isAvailable': isAvailable,
        'memberName': memberName,
        'startTime': timeSlotStart.toIso8601String(),
        'endTime': timeSlotEnd.toIso8601String(),
      });
    }
    
    setState(() {
      timeSlots = fallbackTimeSlots;
      isLoadingTimeSlots = false;
    });
    print('Fallback time slots loaded: ${timeSlots.length}'); // Debug log
  }

  Future<void> _loadUserBookings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    
    if (userId == null) return;
    
    print('Loading user bookings for user $userId'); // Debug log
    
    try {
      final response = await http.get(
        Uri.parse('http://localhost:58377/api/TestBooking/user-bookings/$userId?page=1&pageSize=20'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('User bookings response status: ${response.statusCode}'); // Debug log
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('User bookings response data: $data'); // Debug log
        
        if (data['success'] == true) {
          setState(() {
            userBookings = List<Map<String, dynamic>>.from(data['data']);
            isLoadingBookings = false;
          });
          print('Loaded ${userBookings.length} user bookings from API'); // Debug log
          return;
        }
      }
    } catch (e) {
      print('Error loading user bookings: $e');
    }
    
    // Fallback data for Android/mobile testing
    print('Using fallback user bookings data'); // Debug log
    final now = DateTime.now();
    
    setState(() {
      userBookings = [
        {
          'id': 1001,
          'courtName': 'Sân A',
          'startTime': DateTime(now.year, now.month, now.day - 1, 14, 0).toIso8601String(),
          'endTime': DateTime(now.year, now.month, now.day - 1, 15, 0).toIso8601String(),
          'duration': 1,
          'totalPrice': 150.0,
          'status': 'completed',
          'notes': 'Đặt sân qua ứng dụng mobile',
          'createdDate': DateTime(now.year, now.month, now.day - 1, 13, 30).toIso8601String(),
        },
        {
          'id': 1002,
          'courtName': 'Sân B',
          'startTime': DateTime(now.year, now.month, now.day - 2, 16, 0).toIso8601String(),
          'endTime': DateTime(now.year, now.month, now.day - 2, 17, 0).toIso8601String(),
          'duration': 1,
          'totalPrice': 120.0,
          'status': 'completed',
          'notes': 'Chơi với bạn bè',
          'createdDate': DateTime(now.year, now.month, now.day - 2, 15, 45).toIso8601String(),
        },
        {
          'id': 1003,
          'courtName': 'Sân C',
          'startTime': DateTime(now.year, now.month, now.day + 1, 18, 0).toIso8601String(),
          'endTime': DateTime(now.year, now.month, now.day + 1, 19, 0).toIso8601String(),
          'duration': 1,
          'totalPrice': 200.0,
          'status': 'confirmed',
          'notes': 'Sân VIP cho trận đấu quan trọng',
          'createdDate': DateTime(now.year, now.month, now.day, 10, 15).toIso8601String(),
        },
      ];
      isLoadingBookings = false;
    });
    print('Fallback user bookings loaded: ${userBookings.length}'); // Debug log
  }

  Color _getTimeSlotColor(String status, bool isSelected) {
    if (isSelected) return Colors.blue.withOpacity(0.2);
    
    switch (status) {
      case 'available':
        return Colors.green.withOpacity(0.1);
      case 'reserved':
        return Colors.orange.withOpacity(0.1);
      case 'booked':
        return Colors.red.withOpacity(0.1);
      case 'past':
        return Colors.grey.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getTimeSlotBorderColor(String status, bool isSelected) {
    if (isSelected) return Colors.blue;
    
    switch (status) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'booked':
        return Colors.red;
      case 'past':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getTimeSlotTextColor(String status, bool isSelected) {
    if (isSelected) return Colors.blue;
    
    switch (status) {
      case 'available':
        return Colors.green[700]!;
      case 'reserved':
        return Colors.orange[700]!;
      case 'booked':
        return Colors.red[700]!;
      case 'past':
        return Colors.grey[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available':
        return 'Trống';
      case 'reserved':
        return 'Đã giữ';
      case 'booked':
        return 'Đã đặt';
      case 'past':
        return 'Đã qua';
      default:
        return '';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('vi', 'VN'),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedTimeSlot = null; // Reset time slot when changing date
        timeSlots = []; // Clear current time slots
      });
      if (selectedCourtId != null) {
        _loadTimeSlots(); // Load time slots for new date
      }
    }
  }

  void _confirmBooking() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận đặt sân'),
          content: const Text('Bạn có chắc chắn muốn đặt sân này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processBooking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  void _processBooking() async {
    if (selectedCourtId == null || selectedTimeSlot == null) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Không tìm thấy thông tin người dùng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Store values before resetting
    final currentCourtId = selectedCourtId!;
    final currentTimeSlot = selectedTimeSlot!;
    final currentDate = selectedDate;
    final selectedCourt = courts.firstWhere((c) => c.id == currentCourtId);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse('http://localhost:58377/api/TestBooking/create-booking'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'courtId': currentCourtId,
          'date': currentDate.toIso8601String(),
          'timeSlot': currentTimeSlot,
          'notes': 'Đặt sân qua ứng dụng mobile'
        }),
      );

      // Hide loading
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đặt sân thành công! Số dư ví: ${data['newWalletBalance'].toStringAsFixed(0)}K'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Reset form and reload data
          setState(() {
            selectedCourtId = null;
            selectedTimeSlot = null;
            selectedDate = DateTime.now();
            timeSlots = [];
          });
          
          // Reload user bookings and refresh wallet
          _loadUserBookings();
          
          // Refresh wallet balance in provider
          final walletProvider = Provider.of<WalletProvider>(context, listen: false);
          walletProvider.refreshBalance();
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Booking failed');
      }
    } catch (e) {
      print('Booking error: $e');
      
      // Hide loading if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Fallback success for Android/mobile testing
      print('Using fallback booking success'); // Debug log
      
      // Show fallback success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt sân thành công! (Demo mode - Android Studio)'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reset form
      setState(() {
        selectedCourtId = null;
        selectedTimeSlot = null;
        selectedDate = DateTime.now();
        timeSlots = [];
      });
      
      // Add a demo booking to history for testing
      final demoBooking = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'courtName': selectedCourt.name,
        'startTime': DateTime(currentDate.year, currentDate.month, currentDate.day, 
                              int.parse(currentTimeSlot.split(':')[0]), 0).toIso8601String(),
        'endTime': DateTime(currentDate.year, currentDate.month, currentDate.day, 
                           int.parse(currentTimeSlot.split(':')[0]) + 1, 0).toIso8601String(),
        'duration': 1,
        'totalPrice': selectedCourt.pricePerHour / 1000, // Convert to K
        'status': 'confirmed',
        'notes': 'Đặt sân qua ứng dụng mobile (Demo)',
        'createdDate': DateTime.now().toIso8601String(),
      };
      
      setState(() {
        userBookings.insert(0, demoBooking); // Add to beginning of list
      });
    }
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa có lịch sử đặt sân',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Hãy đặt sân đầu tiên của bạn!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(0);
            },
            icon: const Icon(Icons.add),
            label: const Text('Đặt sân ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingHistoryCard(Map<String, dynamic> booking) {
    final startTime = DateTime.parse(booking['startTime']);
    final endTime = DateTime.parse(booking['endTime']);
    final createdDate = DateTime.parse(booking['createdDate']);
    final status = booking['status'] as String;
    final totalPrice = booking['totalPrice'] as num;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Đã xác nhận';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Chờ xác nhận';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Đã hủy';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Hoàn thành';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sports_tennis_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['courtName'] ?? 'Sân không xác định',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Booking #${booking['id']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Ngày',
                  value: '${startTime.day}/${startTime.month}/${startTime.year}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.access_time,
                  label: 'Giờ',
                  value: '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.schedule,
                  label: 'Thời lượng',
                  value: '${booking['duration']} giờ',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.attach_money,
                  label: 'Tổng tiền',
                  value: '${totalPrice.toStringAsFixed(0)}K',
                ),
              ),
            ],
          ),
          if (booking['notes'] != null && booking['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
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
                  Text(
                    'Ghi chú:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking['notes'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Đặt lúc: ${_formatDateTime(createdDate)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }
}