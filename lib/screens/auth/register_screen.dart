// lib/screens/auth/register_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_dialog.dart';
import '../../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

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
      duration: const Duration(milliseconds: 1200),
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
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // ✅ Listen to password changes for strength indicator
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ UPDATE PASSWORD STRENGTH INDICATORS
  void _updatePasswordStrength() {
    final password = _passwordController.text;
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với Điều khoản sử dụng'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const LoadingDialog(message: 'Đang tạo tài khoản...'),
    );

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      // ✅ Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      if (success) {
        if (mounted) {
          // ✅ Show success dialog instead of just snackbar
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon:
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
              title: const Text('Đăng ký thành công!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Chào mừng ${_nameController.text} đến với Todo App!'),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn đã được đăng nhập tự động và có thể bắt đầu sử dụng ứng dụng.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to login/main
                  },
                  child: const Text('Bắt đầu sử dụng'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(authProvider.error ?? 'Đăng ký thất bại');
        }
      }
    } catch (e) {
      // ✅ Hide loading dialog if error
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        _showErrorDialog('Đã xảy ra lỗi không mong muốn: ${e.toString()}');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi đăng ký'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          if (message.contains('Email đã được sử dụng'))
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to login
              },
              child: const Text('Đăng nhập'),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  size: 16,
                  color: _isPasswordStrong ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Độ mạnh mật khẩu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isPasswordStrong ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStrengthItem('Ít nhất 8 ký tự', _hasMinLength),
            _buildStrengthItem('Có chữ hoa (A-Z)', _hasUppercase),
            _buildStrengthItem('Có chữ thường (a-z)', _hasLowercase),
            _buildStrengthItem('Có số (0-9)', _hasDigits),
            _buildStrengthItem(
                'Có ký tự đặc biệt (!@#\$...)', _hasSpecialChars),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isValid ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ ENHANCED HEADER
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green,
                          Colors.green.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.person_add_outlined,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Tạo tài khoản mới',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Điền thông tin để tạo tài khoản Todo App',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // ✅ ENHANCED REGISTER FORM
                  Card(
                    elevation: 8,
                    shadowColor: Colors.green.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ✅ NAME FIELD với validation theo API
                            CustomTextField(
                              controller: _nameController,
                              labelText: 'Họ và tên',
                              prefixIcon: Icons.person_outlined,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateName,
                              autofillHints: const [AutofillHints.name],
                            ),

                            const SizedBox(height: 16),

                            // ✅ EMAIL FIELD với validation theo API
                            CustomTextField(
                              controller: _emailController,
                              labelText: 'Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateEmailForRegister,
                              autofillHints: const [AutofillHints.email],
                            ),

                            const SizedBox(height: 16),

                            // ✅ PASSWORD FIELD với strength validation
                            CustomTextField(
                              controller: _passwordController,
                              labelText: 'Mật khẩu',
                              prefixIcon: Icons.lock_outlined,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateStrongPassword,
                              autofillHints: const [AutofillHints.newPassword],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ✅ PASSWORD STRENGTH INDICATOR
                            if (_passwordController.text.isNotEmpty)
                              _buildPasswordStrengthIndicator(),

                            if (_passwordController.text.isNotEmpty)
                              const SizedBox(height: 16),

                            // ✅ CONFIRM PASSWORD FIELD
                            CustomTextField(
                              controller: _confirmPasswordController,
                              labelText: 'Xác nhận mật khẩu',
                              prefixIcon: Icons.lock_outlined,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              validator: (value) =>
                                  Validators.validateConfirmPassword(
                                value,
                                _passwordController.text,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              onFieldSubmitted: (_) => _register(),
                            ),

                            const SizedBox(height: 16),

                            // ✅ TERMS AND CONDITIONS CHECKBOX
                            Row(
                              children: [
                                Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _agreeToTerms = value ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _agreeToTerms = !_agreeToTerms;
                                      });
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        style: theme.textTheme.bodySmall,
                                        children: [
                                          const TextSpan(
                                              text: 'Tôi đồng ý với '),
                                          TextSpan(
                                            text: 'Điều khoản sử dụng',
                                            style: TextStyle(
                                              color: theme.primaryColor,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                          const TextSpan(text: ' và '),
                                          TextSpan(
                                            text: 'Chính sách bảo mật',
                                            style: TextStyle(
                                              color: theme.primaryColor,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ✅ REGISTER BUTTON
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return CustomButton(
                                  onPressed:
                                      authProvider.isLoading ? null : _register,
                                  isLoading: authProvider.isLoading,
                                  text: 'Tạo tài khoản',
                                  icon: Icons.person_add,
                                  backgroundColor: Colors.green,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ✅ DEVELOPMENT INFO (chỉ hiện trong debug mode)
                  if (kDebugMode) ...[
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.green.shade700, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Password Requirements (API)',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'API yêu cầu mật khẩu mạnh:\n'
                              '• Ít nhất 8 ký tự\n'
                              '• Có chữ hoa, chữ thường\n'
                              '• Có số và ký tự đặc biệt\n'
                              '• Tên: max 100 ký tự\n'
                              '• Email: max 255 ký tự',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ✅ LOGIN LINK với enhanced design
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã có tài khoản? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Đăng nhập ngay',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ✅ API VERSION INFO
                  Text(
                    'Version 1.0.0 • Powered by .NET 8 API',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
