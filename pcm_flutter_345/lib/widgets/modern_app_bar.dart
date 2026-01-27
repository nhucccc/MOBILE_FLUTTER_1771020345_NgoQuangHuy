import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final bool centerTitle;
  final Widget? flexibleSpace;
  final double elevation;
  final bool automaticallyImplyLeading;

  const ModernAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.centerTitle = true,
    this.flexibleSpace,
    this.elevation = 0,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTheme.titleLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.neutral900,
        ),
      ),
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: leading ?? (showBackButton && Navigator.canPop(context)
          ? _buildBackButton(context)
          : null),
      actions: actions,
      flexibleSpace: flexibleSpace,
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: onBackPressed ?? () => Navigator.of(context).pop(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            boxShadow: AppTheme.shadowSM,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppTheme.neutral700,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: GlassCard(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        child: Row(
          children: [
            if (showBackButton && Navigator.canPop(context))
              GestureDetector(
                onTap: onBackPressed ?? () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            if (leading != null) leading!,
            if (showBackButton || leading != null) 
              const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Text(
                title,
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutral900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actions != null) ...[
              const SizedBox(width: AppTheme.spacing12),
              ...actions!,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}