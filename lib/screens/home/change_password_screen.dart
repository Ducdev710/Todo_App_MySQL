// lib/screens/home/change_password_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_dialog.dart';
import '../../utils/validators.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ✅ PASSWORD STRENGTH INDICATORS
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigits = false;
  bool _hasSpecialChars = false;

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
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // ✅ Listen to password changes for strength indicator
    _newPasswordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ UPDATE PASSWORD STRENGTH INDICATORS
  void _updatePasswordStrength() {
    final password = _newPasswordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigits = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  bool get _isPasswordStrong {
    return _hasMinLength &&
        _hasUppercase &&
        _hasLowercase &&
        _hasDigits &&
        _hasSpecialChars;
  }

  int get _passwordStrengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasDigits) score++;
    if (_hasSpecialChars) score++;
    return score;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Additional validation for strong password
    if (!_isPasswordStrong) {
      _showErrorDialog(
        'Mật khẩu mới chưa đủ mạnh',
        'Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt.',
      );
      return;
    }

    // ✅ Show loading dialog
    LoadingDialog.show(
      context,
      message: 'Đang đổi mật khẩu...',
      canCancel: false,
    );

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
        _confirmPasswordController.text,
      );

      // ✅ Hide loading dialog
      if (mounted) LoadingDialog.hide(context);

      if (success) {
        if (mounted) {
          // ✅ Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon:
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
              title: const Text('Đổi mật khẩu thành công!'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Mật khẩu của bạn đã được cập nhật.'),
                  SizedBox(height: 8),
                  Text(
                    'Vui lòng đăng nhập lại với mật khẩu mới.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to settings
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(
            'Đổi mật khẩu thất bại',
            'Có lỗi xảy ra. Vui lòng thử lại sau.',
          );
        }
      }
    } catch (e) {
      // ✅ Hide loading dialog if error occurs
      if (mounted) LoadingDialog.hide(context);

      if (kDebugMode) {
        print('Error changing password: $e');
      }

      if (mounted) {
        _showErrorDialog(
          'Lỗi kết nối',
          'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối internet.',
        );
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 64),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ HEADER với icon và text
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade800,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bảo mật tài khoản',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Thay đổi mật khẩu để bảo vệ tài khoản',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ✅ FORM FIELDS
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ CURRENT PASSWORD - SỬA LỖI: AutofillHints.password
                            CustomTextField(
                              controller: _currentPasswordController,
                              labelText: 'Mật khẩu hiện tại',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Vui lòng nhập mật khẩu hiện tại';
                                }
                                return null;
                              },
                              autofillHints: const [
                                AutofillHints.password
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ✅ NEW PASSWORD
                            CustomTextField(
                              controller: _newPasswordController,
                              labelText: 'Mật khẩu mới',
                              prefixIcon: Icons.lock,
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateStrongPassword,
                              autofillHints: const [
                                AutofillHints.newPassword
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ✅ PASSWORD STRENGTH INDICATOR
                            if (_newPasswordController.text.isNotEmpty) ...[
                              const Text(
                                'Độ mạnh mật khẩu:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildPasswordStrengthIndicator(),
                              const SizedBox(height: 16),
                            ],

                            // ✅ CONFIRM PASSWORD
                            CustomTextField(
                              controller: _confirmPasswordController,
                              labelText: 'Xác nhận mật khẩu mới',
                              prefixIcon: Icons.lock_reset,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              validator: (value) => Validators.validateConfirmPassword(
                                value,
                                _newPasswordController.text,
                              ),
                              autofillHints: const [
                                AutofillHints.newPassword
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ✅ PASSWORD REQUIREMENTS
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Yêu cầu mật khẩu:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPasswordRequirement(
                                    'Ít nhất 8 ký tự',
                                    _hasMinLength,
                                  ),
                                  _buildPasswordRequirement(
                                    'Có chữ hoa (A-Z)',
                                    _hasUppercase,
                                  ),
                                  _buildPasswordRequirement(
                                    'Có chữ thường (a-z)',
                                    _hasLowercase,
                                  ),
                                  _buildPasswordRequirement(
                                    'Có số (0-9)',
                                    _hasDigits,
                                  ),
                                  _buildPasswordRequirement(
                                    'Có ký tự đặc biệt (!@#\$...)',
                                    _hasSpecialChars,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ✅ ACTION BUTTONS
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Column(
                            children: [
                              CustomButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _changePassword,
                                text: authProvider.isLoading
                                    ? 'Đang xử lý...'
                                    : 'Đổi mật khẩu',
                                icon: Icons.security,
                                width: double.infinity,
                              ),
                              const SizedBox(height: 12),
                              CustomButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => Navigator.pop(context),
                                text: 'Hủy',
                                icon: Icons.cancel, // SỬA LỖI: Icons.cancel thay vì Icons.cancel_outline
                                width: double.infinity,
                                isOutlined: true,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final score = _passwordStrengthScore;
    final percentage = score / 5;

    Color getStrengthColor() {
      if (score <= 1) return Colors.red;
      if (score <= 2) return Colors.orange;
      if (score <= 3) return Colors.yellow;
      if (score <= 4) return Colors.lightGreen;
      return Colors.green;
    }

    String getStrengthText() {
      if (score <= 1) return 'Rất yếu';
      if (score <= 2) return 'Yếu';
      if (score <= 3) return 'Trung bình';
      if (score <= 4) return 'Mạnh';
      return 'Rất mạnh';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(getStrengthColor()),
                minHeight: 6,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              getStrengthText(),
              style: TextStyle(
                color: getStrengthColor(),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green.shade700 : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
