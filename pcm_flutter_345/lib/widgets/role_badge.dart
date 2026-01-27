import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/role_utils.dart';

class RoleBadge extends StatelessWidget {
  final String? role;
  final bool showDescription;
  final double? fontSize;

  const RoleBadge({
    super.key,
    required this.role,
    this.showDescription = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getRoleColor(role);
    final displayName = RoleUtils.getRoleDisplayName(role);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(role),
            color: color,
            size: (fontSize ?? 14) + 2,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize ?? 14,
                ),
              ),
              if (showDescription) ...[
                const SizedBox(height: 2),
                Text(
                  RoleUtils.getRoleDescription(role),
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: (fontSize ?? 14) - 2,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Treasurer':
        return Icons.account_balance;
      case 'Referee':
        return Icons.sports;
      case 'Member':
        return Icons.person;
      default:
        return Icons.person;
    }
  }
}

class RoleHeader extends StatelessWidget {
  final String? role;
  final String userName;
  final String? avatarUrl;

  const RoleHeader({
    super.key,
    required this.role,
    required this.userName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppTheme.getRoleGradient(role);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: avatarUrl != null 
                    ? NetworkImage(avatarUrl!) 
                    : null,
                  child: avatarUrl == null 
                    ? Icon(
                        Icons.person,
                        size: 35,
                        color: Colors.white.withOpacity(0.8),
                      )
                    : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào,',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RoleBadge(
                        role: role,
                        showDescription: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}