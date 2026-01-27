import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool showShadow;
  final Border? border;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.gradient,
    this.onTap,
    this.showShadow = true,
    this.border,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _shadowAnimation = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _animationController.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              margin: widget.margin ?? const EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: widget.gradient == null ? (widget.color ?? AppTheme.surfaceColor) : null,
                gradient: widget.gradient,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusLG),
                border: widget.border ?? Border.all(
                  color: AppTheme.neutral200,
                  width: 0.5,
                ),
                boxShadow: widget.showShadow ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08 * _shadowAnimation.value),
                    blurRadius: 20 * _shadowAnimation.value,
                    offset: Offset(0, 8 * _shadowAnimation.value),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04 * _shadowAnimation.value),
                    blurRadius: 6 * _shadowAnimation.value,
                    offset: Offset(0, 2 * _shadowAnimation.value),
                  ),
                ] : null,
              ),
              child: ClipRRect(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusLG),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.all(AppTheme.spacing16),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StatsCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.color ?? AppTheme.primaryColor;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomCard(
              onTap: widget.onTap,
              gradient: LinearGradient(
                colors: [
                  cardColor,
                  cardColor.withOpacity(0.8),
                  cardColor.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  
                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacing12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          if (widget.onTap != null)
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      Text(
                        widget.value,
                        style: AppTheme.headlineLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        widget.title,
                        style: AppTheme.titleMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          widget.subtitle!,
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ActionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  final bool enabled;

  const ActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.color,
    this.enabled = true,
  });

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Staggered animation
    Future.delayed(Duration(milliseconds: 100 * (widget.hashCode % 5)), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.color ?? AppTheme.primaryColor;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomCard(
              onTap: widget.enabled ? widget.onTap : null,
              color: widget.enabled ? Colors.white : AppTheme.neutral100,
              border: Border.all(
                color: widget.enabled 
                    ? cardColor.withOpacity(0.1)
                    : AppTheme.neutral200,
                width: 1,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: widget.enabled
                          ? LinearGradient(
                              colors: [
                                cardColor.withOpacity(0.1),
                                cardColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: widget.enabled ? null : AppTheme.neutral200,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.enabled 
                          ? cardColor
                          : AppTheme.neutral400,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    widget.title,
                    style: AppTheme.titleMedium.copyWith(
                      color: widget.enabled 
                          ? AppTheme.neutral900
                          : AppTheme.neutral400,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    widget.description,
                    style: AppTheme.bodySmall.copyWith(
                      color: widget.enabled 
                          ? AppTheme.neutral600
                          : AppTheme.neutral400,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}