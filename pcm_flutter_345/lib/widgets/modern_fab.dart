import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool extended;
  final List<ModernFABAction>? actions;

  const ModernFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.extended = false,
    this.actions,
  });

  @override
  State<ModernFAB> createState() => _ModernFABState();
}

class _ModernFABState extends State<ModernFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actions != null && widget.actions!.isNotEmpty) {
      return _buildExpandableFAB();
    }

    return _buildSimpleFAB();
  }

  Widget _buildSimpleFAB() {
    if (widget.extended && widget.label != null) {
      return FloatingActionButton.extended(
        onPressed: widget.onPressed,
        icon: Icon(widget.icon),
        label: Text(
          widget.label!,
          style: AppTheme.labelLarge.copyWith(
            color: widget.foregroundColor ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: widget.backgroundColor ?? AppTheme.primaryColor,
        foregroundColor: widget.foregroundColor ?? Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.shadowLG,
      ),
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        backgroundColor: Colors.transparent,
        foregroundColor: widget.foregroundColor ?? Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        child: Icon(widget.icon, size: 28),
      ),
    );
  }

  Widget _buildExpandableFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action buttons
        ...widget.actions!.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          
          return AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    -_scaleAnimation.value * (index + 1) * 70,
                  ),
                  child: Opacity(
                    opacity: _scaleAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (action.label != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing12,
                                vertical: AppTheme.spacing8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                              ),
                              child: Text(
                                action.label!,
                                style: AppTheme.labelSmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing8),
                          ],
                          FloatingActionButton.small(
                            onPressed: action.onPressed,
                            backgroundColor: action.backgroundColor ?? AppTheme.primaryColor,
                            foregroundColor: action.foregroundColor ?? Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            ),
                            child: Icon(action.icon, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
        
        // Main FAB
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: AppTheme.shadowLG,
          ),
          child: FloatingActionButton(
            onPressed: _toggleExpanded,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            ),
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isExpanded ? Icons.close : widget.icon,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ModernFABAction {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ModernFABAction({
    required this.onPressed,
    required this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
  });
}