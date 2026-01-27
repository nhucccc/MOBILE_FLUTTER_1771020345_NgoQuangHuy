import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          kBottomNavigationBarHeight + 32,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security info card
              _buildSecurityInfoCard(),
              const SizedBox(height: 24),
              
              // Form fields
              _buildFormFields(),
              const SizedBox(height: 32),
              
              // Change password button
              _buildChangePasswordButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityInfoCard() {
    return SimpleCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.security,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bảo mật tài khoản',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thay đổi mật khẩu để bảo vệ tài khoản của bạn',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Password
        Text(
          'Mật khẩu hiện tại',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SimpleCard(
          child: TextFormField(
            controller: _currentPasswordController,
            obscureText: !_showCurrentPassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _showCurrentPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _showCurrentPassword = !_showCurrentPassword;
                  });
                },
              ),
              border: InputBorder.none,
              hintText: 'Nhập mật khẩu hiện tại',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu hiện tại';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),
        
        // New Password
        Text(
          'Mật khẩu mới',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SimpleCard(
          child: TextFormField(
            controller: _newPasswordController,
            obscureText: !_showNewPassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _showNewPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _showNewPassword = !_showNewPassword;
                  });
                },
              ),
              border: InputBorder.none,
              hintText: 'Nhập mật khẩu mới',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu mới';
              }
              if (value.length < 6) {
                return 'Mật khẩu phải có ít nhất 6 ký tự';
              }
              if (value == _currentPasswordController.text) {
                return 'Mật khẩu mới phải khác mật khẩu hiện tại';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {}); // Trigger rebuild for password strength
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordStrengthIndicator(),
        const SizedBox(height: 20),
        
        // Confirm Password
        Text(
          'Xác nhận mật khẩu mới',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SimpleCard(
          child: TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_reset),
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _showConfirmPassword = !_showConfirmPassword;
                  });
                },
              ),
              border: InputBorder.none,
              hintText: 'Nhập lại mật khẩu mới',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng xác nhận mật khẩu mới';
              }
              if (value != _newPasswordController.text) {
                return 'Mật khẩu xác nhận không khớp';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _newPasswordController.text;
    final strength = _calculatePasswordStrength(password);
    
    Color strengthColor;
    String strengthText;
    
    if (strength < 0.3) {
      strengthColor = AppTheme.errorColor;
      strengthText = 'Yếu';
    } else if (strength < 0.7) {
      strengthColor = AppTheme.warningColor;
      strengthText = 'Trung bình';
    } else {
      strengthColor = AppTheme.successColor;
      strengthText = 'Mạnh';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength,
                backgroundColor: AppTheme.neutral200,
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strengthText,
              style: AppTheme.labelSmall.copyWith(
                color: strengthColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Mật khẩu nên có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.neutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _changePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security),
                  const SizedBox(width: 8),
                  Text(
                    'Đổi mật khẩu',
                    style: AppTheme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    
    double strength = 0.0;
    
    // Length check
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.15;
    
    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;
    
    return strength.clamp(0.0, 1.0);
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to change password
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Đổi mật khẩu thành công!',
              style: AppTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Mật khẩu của bạn đã được thay đổi thành công. Vui lòng sử dụng mật khẩu mới để đăng nhập lần sau.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close screen
              },
              child: const Text('Hoàn tất'),
            ),
          ),
        ],
      ),
    );
  }
}