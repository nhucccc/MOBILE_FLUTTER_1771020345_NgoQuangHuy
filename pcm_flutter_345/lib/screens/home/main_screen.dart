import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/large_bottom_nav.dart';
import '../../widgets/premium_bottom_nav.dart';
import '../home/fixed_dashboard_home_screen.dart';
import '../booking/simple_booking_screen.dart';
import '../tournament/enhanced_tournaments_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/enhanced_admin_dashboard_screen.dart';
import '../treasurer/enhanced_treasurer_dashboard_screen.dart';
import '../referee/enhanced_referee_dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Method để change tab từ bên ngoài
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final role = user?.role?.toLowerCase();
        
        print('MainScreen - User: ${user?.fullName}, Role: $role'); // Debug log
        
        // Define screens based on role with enhanced versions
        List<Widget> screens;
        
        switch (role) {
          case 'admin':
            screens = [
              const EnhancedAdminDashboardScreen(),
              const SimpleBookingScreen(),
              const EnhancedTournamentsScreen(),
              const WalletScreen(),
              const ProfileScreen(),
            ];
            break;
            
          case 'treasurer':
            screens = [
              const EnhancedTreasurerDashboardScreen(),
              const SimpleBookingScreen(),
              const EnhancedTournamentsScreen(),
              const WalletScreen(),
              const ProfileScreen(),
            ];
            break;
            
          case 'referee':
            screens = [
              const EnhancedRefereeDashboardScreen(),
              const SimpleBookingScreen(),
              const EnhancedTournamentsScreen(),
              const WalletScreen(),
              const ProfileScreen(),
            ];
            break;
            
          default: // Regular user
            screens = [
              FixedDashboardHomeScreen(
                onTabChange: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ), // Sử dụng fixed version với light theme và bảng xếp hạng thực tế
              const SimpleBookingScreen(),
              const EnhancedTournamentsScreen(),
              const WalletScreen(),
              const ProfileScreen(),
            ];
            break;
        }
        
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: LargeBottomNav(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}