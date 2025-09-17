// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_dialog.dart';
import '../../utils/validators.dart';
import '../../utils/date_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _hasChanges = false;
  bool _isApiUpdateSupported = true; 

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

    // ✅ Initialize với current user data
    _initializeUserData();

    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeUserData() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      _nameController.text = authProvider.currentUser!.name;
      _emailController.text = authProvider.currentUser!.email;
    }
  }

  void _onFieldChanged() {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser != null) {
      final hasNameChanged = _nameController.text.trim() != currentUser.name;
      final hasEmailChanged = _emailController.text.trim() != currentUser.email;

      setState(() {
        _hasChanges = hasNameChanged || hasEmailChanged;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // Bỏ phần check _isApiUpdateSupported và hiển thị dialog
    // Gọi trực tiếp update profile
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.updateProfile(name, email);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cập nhật thông tin thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${authProvider.error ?? 'Cập nhật thất bại'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showApiLimitationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Thông báo'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('API hiện tại chưa hỗ trợ cập nhật thông tin người dùng.'),
                SizedBox(height: 8),
                Text(
                    'Thay đổi sẽ được lưu cục bộ và có thể bị mất khi đăng nhập lại.'),
                SizedBox(height: 8),
                Text(
                  'Bạn có muốn tiếp tục không?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Tiếp tục'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeAvatarDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thay đổi ảnh đại diện'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tính năng này sẽ được cập nhật trong phiên bản tương lai.'),
            SizedBox(height: 16),
            Text('Hiện tại, ảnh đại diện được tạo từ chữ cái đầu của tên bạn.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          if (shouldPop) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: const Text('Chỉnh sửa thông tin'),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return TextButton(
                  onPressed: authProvider.isLoading || !_hasChanges
                      ? null
                      : _saveProfile,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Lưu',
                          style: TextStyle(
                            color: _hasChanges ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ✅ ENHANCED PROFILE AVATAR
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Card(
                          elevation: 8,
                          shadowColor: theme.primaryColor.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.primaryColor,
                                            theme.primaryColor.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.white,
                                        child: Text(
                                          authProvider.userInitials,
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: _showChangeAvatarDialog,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Thay đổi ảnh đại diện',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ✅ FORM FIELDS với custom widgets
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin cơ bản',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ✅ NAME FIELD với custom widget
                            CustomTextField(
                              controller: _nameController,
                              labelText: 'Họ và tên',
                              prefixIcon: Icons.person_outline,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateName,
                              autofillHints: const [AutofillHints.name],
                            ),

                            const SizedBox(height: 16),

                            // ✅ EMAIL FIELD với custom widget
                            CustomTextField(
                              controller: _emailController,
                              labelText: 'Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: Validators.validateEmailForRegister,
                              autofillHints: const [AutofillHints.email],
                            ),

                            const SizedBox(height: 20),

                            // ✅ ENHANCED CHANGES INDICATOR
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: _hasChanges ? null : 0,
                              child: _hasChanges
                                  ? Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange.shade50,
                                            Colors.orange.shade100,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.orange.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_note,
                                            color: Colors.orange.shade700,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Có thay đổi chưa lưu',
                                                  style: TextStyle(
                                                    color:
                                                        Colors.orange.shade700,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  'Nhấn "Lưu" để cập nhật thông tin',
                                                  style: TextStyle(
                                                    color:
                                                        Colors.orange.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ ENHANCED ACCOUNT INFO
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final user = authProvider.currentUser;
                        if (user == null) return const SizedBox();

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thông tin tài khoản',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                _buildInfoRow(
                                  icon: Icons.badge_outlined,
                                  label: 'ID tài khoản',
                                  value: '#${user.id}',
                                  theme: theme,
                                ),

                                _buildInfoRow(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Ngày tham gia',
                                  value: DateTimeUtils.formatFullDate(
                                      user.createdAt),
                                  theme: theme,
                                ),

                                _buildInfoRow(
                                  icon: Icons.update_outlined,
                                  label: 'Cập nhật lần cuối',
                                  value: DateTimeUtils.formatRelativeDate(
                                      user.updatedAt),
                                  theme: theme,
                                ),

                                // ✅ New user indicator
                                if (authProvider.isNewUser)
                                  _buildInfoRow(
                                    icon: Icons.star_outline,
                                    label: 'Trạng thái',
                                    value: 'Thành viên mới',
                                    theme: theme,
                                    valueColor: Colors.orange,
                                  ),

                                _buildInfoRow(
                                  icon: Icons.email_outlined,
                                  label: 'Domain email',
                                  value: authProvider.userEmailDomain.isNotEmpty
                                      ? '@${authProvider.userEmailDomain}'
                                      : 'N/A',
                                  theme: theme,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // ✅ DEVELOPMENT INFO (chỉ hiện trong debug mode)
                    if (kDebugMode) ...[
                      const SizedBox(height: 20),
                      Card(
                        color: Colors.orange.shade50,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.developer_mode,
                                      color: Colors.orange.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Development Info',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'API Limitation: Backend chưa có endpoint update profile.\n'
                                'Mock update được sử dụng (chỉ local storage).\n'
                                'Cần implement: PUT /api/users/{id} endpoint.',
                                style: TextStyle(
                                  color: Colors.orange.shade600,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ✅ SAVE BUTTON với custom widget
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return CustomButton(
                          onPressed: authProvider.isLoading || !_hasChanges
                              ? null
                              : _saveProfile,
                          text: 'Lưu thay đổi',
                          icon: Icons.save,
                          isLoading: authProvider.isLoading,
                          width: double.infinity,
                          backgroundColor: theme.primaryColor,
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // ✅ CANCEL BUTTON
                    CustomButton(
                      onPressed: () {
                        if (_hasChanges) {
                          _showUnsavedChangesDialog().then((shouldPop) {
                            if (shouldPop) Navigator.of(context).pop();
                          });
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      text: 'Hủy',
                      icon: Icons.cancel,
                      width: double.infinity,
                      isOutlined: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Có thay đổi chưa lưu'),
            content: const Text(
                'Bạn có thay đổi chưa được lưu. Bạn có muốn rời khỏi mà không lưu không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ở lại'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Rời khỏi'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
