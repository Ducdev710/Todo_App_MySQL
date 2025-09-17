// lib/screens/auth/login_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_dialog.dart';
import '../../utils/validators.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    // ✅ Load saved credentials if remember me was enabled
    if (mounted) {
      _loadSavedCredentials();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ LOAD SAVED CREDENTIALS IF REMEMBER ME WAS ENABLED
  Future<void> _loadSavedCredentials() async {
    print('🔍 Loading saved credentials...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberedEmail = prefs.getString('remembered_email');
      final rememberedPassword = prefs.getString('remembered_password');
      final rememberMe = prefs.getBool('remember_me') ?? false;

      print('🔍 Found saved data: email=$rememberedEmail, password=${rememberedPassword != null ? "[hidden]" : "null"}, rememberMe=$rememberMe');

      if (rememberMe && rememberedEmail != null && rememberedPassword != null) {
        _emailController.text = rememberedEmail;
        _passwordController.text = rememberedPassword;
        setState(() {
          _rememberMe = true;
        });
        print('✅ Credentials loaded and auto-filled');
      } else {
        print('ℹ️ No saved credentials to load');
      }
    } catch (e) {
      print('❌ Error loading saved credentials: $e');
    }
  }

  // ✅ SAVE CREDENTIALS IF REMEMBER ME IS ENABLED
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_rememberMe) {
        await prefs.setString('remembered_email', _emailController.text.trim());
        await prefs.setString('remembered_password', _passwordController.text);
        await prefs.setBool('remember_me', true);
        print('✅ Credentials saved');
      } else {
        // Clear saved credentials if remember me is disabled
        await prefs.remove('remembered_email');
        await prefs.remove('remembered_password');
        await prefs.setBool('remember_me', false);
        print('🗑️ Credentials cleared');
      }
    } catch (e) {
      print('❌ Error saving credentials: $e');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(message: 'Đang đăng nhập...'),
    );

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // ✅ Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // ✅ Save credentials if remember me is enabled
        await _saveCredentials();
        
        // ✅ Success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Chào mừng ${authProvider.userDisplayName}!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // ✅ Enhanced error handling
        if (mounted) {
          _showErrorDialog(authProvider.error ?? 'Đăng nhập thất bại');
        }
      }
    } catch (e) {
      // ✅ Hide loading dialog nếu có lỗi
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
            Text('Lỗi đăng nhập'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          if (message.contains('server') || message.contains('kết nối'))
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _testConnection();
              },
              child: const Text('Kiểm tra kết nối'),
            ),
        ],
      ),
    );
  }

  // ✅ TEST API CONNECTION
  Future<void> _testConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(message: 'Kiểm tra kết nối...'),
    );

    try {
      final authProvider = context.read<AuthProvider>();
      final isConnected = await authProvider.checkApiConnection();

      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(isConnected
                    ? 'Kết nối server thành công!'
                    : 'Không thể kết nối server. Kiểm tra server có chạy tại https://localhost:7215'),
              ],
            ),
            backgroundColor: isConnected ? Colors.green : Colors.red,
            duration: Duration(seconds: isConnected ? 2 : 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kiểm tra kết nối: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // ✅ ENHANCED LOGO AND TITLE
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Todo App',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng nhập để quản lý công việc hiệu quả',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // ✅ ENHANCED LOGIN FORM
                Card(
                  elevation: 8,
                  shadowColor: theme.primaryColor.withOpacity(0.2),
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
                          // ✅ TITLE INSIDE CARD
                          Text(
                            'Đăng nhập',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // ✅ EMAIL FIELD với enhanced validation
                          CustomTextField(
                            controller: _emailController,
                            labelText: 'Email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validators.validateEmail,
                            autofillHints: const [AutofillHints.email],
                          ),

                          const SizedBox(height: 16),

                          // ✅ PASSWORD FIELD với enhanced validation
                          CustomTextField(
                            controller: _passwordController,
                            labelText: 'Mật khẩu',
                            prefixIcon: Icons.lock_outlined,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            validator: Validators.validatePassword,
                            autofillHints: const [AutofillHints.password],
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
                            onFieldSubmitted: (_) => _login(),
                          ),

                          const SizedBox(height: 16),

                          // ✅ REMEMBER ME CHECKBOX
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                              const Text('Ghi nhớ đăng nhập'),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  // TODO: Implement forgot password
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Tính năng đang phát triển'),
                                    ),
                                  );
                                },
                                child: const Text('Quên mật khẩu?'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ✅ LOGIN BUTTON với Consumer
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return CustomButton(
                                onPressed:
                                    authProvider.isLoading ? null : _login,
                                isLoading: authProvider.isLoading,
                                text: 'Đăng nhập',
                                icon: Icons.login,
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
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.developer_mode,
                                  color: Colors.orange.shade700, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Development Mode',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'API Server: https://localhost:7215\n'
                            'Test credentials đã được điền sẵn',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _testConnection,
                            icon: const Icon(Icons.network_check, size: 16),
                            label: const Text('Test Connection',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ✅ REGISTER LINK với enhanced design
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToRegister,
                        child: Text(
                          'Đăng ký ngay',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ APP VERSION INFO
                Text(
                  'Version 1.0.0 • TodoAPI with .NET 8',
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
    );
  }
}
