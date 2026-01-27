import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_card.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  double? _selectedAmount;
  
  final List<double> _quickAmounts = [
    50000,
    100000,
    200000,
    500000,
    1000000,
    2000000,
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nạp tiền vào ví'),
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
              // Số dư hiện tại
              _buildCurrentBalanceCard(),
              const SizedBox(height: 24),
              
              // Chọn số tiền nhanh
              _buildQuickAmountSelection(),
              const SizedBox(height: 24),
              
              // Nhập số tiền tùy chỉnh
              _buildCustomAmountInput(),
              const SizedBox(height: 24),
              
              // Ghi chú
              _buildDescriptionInput(),
              const SizedBox(height: 24),
              
              // Thông tin chuyển khoản
              _buildBankInfoCard(),
              const SizedBox(height: 32),
              
              // Nút nạp tiền
              _buildDepositButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBalanceCard() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
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
                  Icons.account_balance_wallet,
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
                      'Số dư hiện tại',
                      style: AppTheme.labelMedium.copyWith(
                        color: AppTheme.neutral600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${walletProvider.balance.toStringAsFixed(0)}đ',
                      style: AppTheme.headlineMedium.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAmountSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn số tiền nạp',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SimpleCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amount) {
              final isSelected = _selectedAmount == amount;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAmount = amount;
                    _amountController.text = amount.toStringAsFixed(0);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? AppTheme.primaryGradient
                        : null,
                    color: isSelected 
                        ? null 
                        : AppTheme.neutral100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.primaryColor
                          : AppTheme.neutral200,
                    ),
                  ),
                  child: Text(
                    '${amount.toStringAsFixed(0)}đ',
                    style: AppTheme.labelMedium.copyWith(
                      color: isSelected 
                          ? Colors.white
                          : AppTheme.neutral700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoặc nhập số tiền khác',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SimpleCard(
          child: TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'Số tiền (VNĐ)',
              hintText: 'Nhập số tiền muốn nạp',
              prefixIcon: Icon(Icons.payments),
              border: InputBorder.none,
              suffixText: 'đ',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập số tiền';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Số tiền không hợp lệ';
              }
              if (amount < 10000) {
                return 'Số tiền tối thiểu là 10.000đ';
              }
              if (amount > 50000000) {
                return 'Số tiền tối đa là 50.000.000đ';
              }
              return null;
            },
            onChanged: (value) {
              final amount = double.tryParse(value);
              setState(() {
                _selectedAmount = amount;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ghi chú (tùy chọn)',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SimpleCard(
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              hintText: 'Nhập ghi chú cho giao dịch này...',
              prefixIcon: Icon(Icons.note_add),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankInfoCard() {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin chuyển khoản',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Chuyển khoản vào tài khoản dưới đây',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          _buildBankInfoRow('Ngân hàng:', 'Vietcombank'),
          _buildBankInfoRow('Số tài khoản:', '1234567890'),
          _buildBankInfoRow('Chủ tài khoản:', 'PICKLEBALL CLUB'),
          _buildBankInfoRow('Nội dung CK:', 'NAP TIEN [SĐT của bạn]'),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vui lòng ghi đúng nội dung chuyển khoản để được xử lý nhanh chóng',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutral600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Icon(
              Icons.copy,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitDepositRequest,
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
                  const Icon(Icons.send),
                  const SizedBox(width: 8),
                  Text(
                    'Gửi yêu cầu nạp tiền',
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

  Future<void> _submitDepositRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();
      
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      final success = await walletProvider.createDepositRequest(
        amount: amount,
        description: description.isEmpty ? 'Nạp tiền vào ví' : description,
      );

      if (success && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        _showErrorSnackBar(walletProvider.error ?? 'Có lỗi xảy ra');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Lỗi: $e');
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
              'Yêu cầu đã được gửi!',
              style: AppTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Yêu cầu nạp tiền của bạn đã được gửi thành công. Vui lòng chuyển khoản theo thông tin đã cung cấp.',
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}