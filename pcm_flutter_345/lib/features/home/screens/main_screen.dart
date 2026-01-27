import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;

import '../../../core/config/theme_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../wallet/providers/wallet_provider.dart';

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Trang chủ',
      route: '/home',
    ),
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Đặt sân',
      route: '/booking',
    ),
    NavigationItem(
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      label: 'Giải đấu',
      route: '/tournaments',
    ),
    NavigationItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Ví',
      route: '/wallet',
    ),
    NavigationItem(
      icon: Icons.person_outlined,
      activeIcon: Icons.person,
      label: 'Cá nhân',
      route: '/profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      Provider.of<WalletProvider>(context, listen: false).loadWalletBalance();
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    context.go(_navigationItems[index].route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: widget.child,
      bottomNavigationBar: _buildBottomNavigationBar(),
      drawer: _buildDrawer(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PCM - Vợt Thủ Phố Núi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (authProvider.user?.fullName != null)
                Text(
                  'Xin chào, ${authProvider.user!.fullName}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
            ],
          );
        },
      ),
      actions: [
        // Wallet Balance
        Consumer<WalletProvider>(
          builder: (context, walletProvider, child) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ThemeConfig.walletGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ThemeConfig.walletGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 16,
                    color: ThemeConfig.walletGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${walletProvider.balance?.toStringAsFixed(0) ?? '0'}đ',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.walletGreen,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Notifications
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            return badges.Badge(
              badgeContent: Text(
                '${notificationProvider.unreadCount > 99 ? '99+' : notificationProvider.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              showBadge: notificationProvider.unreadCount > 0,
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Add admin tab for admin users
        final items = List<NavigationItem>.from(_navigationItems);
        if (authProvider.isAdmin) {
          items.add(NavigationItem(
            icon: Icons.admin_panel_settings_outlined,
            activeIcon: Icons.admin_panel_settings,
            label: 'Quản lý',
            route: '/admin',
          ));
        }

        return BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: ThemeConfig.primaryColor,
          unselectedItemColor: Colors.grey,
          items: items.map((item) => BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
          )).toList(),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final member = user?.member;

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: ThemeConfig.primaryColor,
                ),
                accountName: Text(user?.fullName ?? 'Người dùng'),
                accountEmail: Text(user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: member?.avatarUrl != null 
                      ? NetworkImage(member!.avatarUrl!) 
                      : null,
                  child: member?.avatarUrl == null 
                      ? Text(
                          user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ThemeConfig.primaryColor,
                          ),
                        )
                      : null,
                ),
                otherAccountsPictures: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(ThemeConfig.tierColors[member?.tier] ?? 0xFF9E9E9E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      member?.tier ?? 'Standard',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Thành viên'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/members');
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Thông báo'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/notifications');
                },
              ),
              if (authProvider.isAdmin) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Quản lý'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin');
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Đăng xuất'),
                onTap: () async {
                  Navigator.pop(context);
                  await authProvider.logout();
                  if (mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}