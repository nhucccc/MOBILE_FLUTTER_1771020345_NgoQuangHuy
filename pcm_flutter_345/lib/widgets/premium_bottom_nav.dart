import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? userRole;

  const PremiumBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navItems = _getNavItems();
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == index;
              
              return Flexible(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: AppTheme.normalAnimation,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.accentColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: AppTheme.normalAnimation,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppTheme.accentColor.withOpacity(0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: isSelected 
                                ? AppTheme.accentColor
                                : Colors.white60,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: AppTheme.normalAnimation,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected 
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected 
                                ? AppTheme.accentColor
                                : Colors.white60,
                          ),
                          child: Text(
                            item['label'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getNavItems() {
    switch (userRole?.toLowerCase()) {
      case 'admin':
        return [
          {'icon': Icons.dashboard, 'label': 'Admin'},
          {'icon': Icons.sports_tennis, 'label': 'Lịch'},
          {'icon': Icons.emoji_events, 'label': 'Giải'},
          {'icon': Icons.account_balance_wallet, 'label': 'Ví'},
          {'icon': Icons.person, 'label': 'Tôi'},
        ];
      case 'treasurer':
        return [
          {'icon': Icons.analytics, 'label': 'Quỹ'},
          {'icon': Icons.sports_tennis, 'label': 'Lịch'},
          {'icon': Icons.emoji_events, 'label': 'Giải'},
          {'icon': Icons.account_balance_wallet, 'label': 'Ví'},
          {'icon': Icons.person, 'label': 'Tôi'},
        ];
      case 'referee':
        return [
          {'icon': Icons.sports_score, 'label': 'Trọng tài'},
          {'icon': Icons.sports_tennis, 'label': 'Lịch'},
          {'icon': Icons.emoji_events, 'label': 'Giải'},
          {'icon': Icons.account_balance_wallet, 'label': 'Ví'},
          {'icon': Icons.person, 'label': 'Tôi'},
        ];
      default:
        return [
          {'icon': Icons.home, 'label': 'Home'},
          {'icon': Icons.sports_tennis, 'label': 'Lịch'},
          {'icon': Icons.emoji_events, 'label': 'Giải'},
          {'icon': Icons.account_balance_wallet, 'label': 'Ví'},
          {'icon': Icons.person, 'label': 'Tôi'},
        ];
    }
  }
}