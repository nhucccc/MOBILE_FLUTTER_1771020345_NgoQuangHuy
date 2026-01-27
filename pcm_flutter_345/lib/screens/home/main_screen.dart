import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_bottom_nav.dart';
import '../home/simple_dashboard_screen.dart';
import '../booking/new_booking_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final role = user?.role?.toLowerCase();
        
        print('MainScreen - User: ${user?.fullName}, Role: $role'); // Debug log
        
        // Define screens based on role
        List<Widget> screens = [
          const SimpleDashboardScreen(),
          const NewBookingScreen(),
          const WalletScreen(),
          const ProfileScreen(),
        ];
        
        // Add admin screen if user is admin
        if (role == 'admin') {
          screens.add(const AdminDashboardScreen());
        }
        
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: SimpleBottomNav(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            userRole: role,
          ),
        );
      },
    );
  }
}