import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SimpleBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? userRole;

  const SimpleBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Trang chủ',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.sports_tennis),
        label: 'Đặt sân',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet),
        label: 'Ví',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Cá nhân',
      ),
    ];

    // Add admin tab if user is admin
    if (userRole?.toLowerCase() == 'admin') {
      items.insert(4, const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Quản trị',
      ));
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.surfaceColor,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.neutral500,
      elevation: 8,
      items: items,
    );
  }
}