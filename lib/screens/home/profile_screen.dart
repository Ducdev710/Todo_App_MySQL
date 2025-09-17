// lib/screens/profile/profile_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../widgets/common/loading_dialog.dart';
import '../../utils/date_utils.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _statsAnimationController;
  late Animation<double> _statsAnimation;

  @override
  bool get wantKeepAlive => true;

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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // ✅ Stats animation controller
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();

    // ✅ Delay stats animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _statsAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    final authProvider = context.read<AuthProvider>();
    final todoProvider = context.read<TodoProvider>();

    try {
      await Future.wait([
        authProvider.refreshUserData(),
        todoProvider.refreshTodos(),
        todoProvider.loadStats(),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.refresh, color: Colors.white),
                SizedBox(width: 8),
                Text('Hồ sơ đã được cập nhật'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Lỗi: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfile,
            tooltip: 'Làm mới hồ sơ',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ✅ ENHANCED PROFILE HEADER
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Card(
                        elevation: 8,
                        shadowColor: theme.primaryColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.primaryColor,
                                theme.primaryColor.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              // ✅ Enhanced avatar với border và animation
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
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
                              const SizedBox(height: 16),

                              // ✅ User name với new user badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      authProvider.userDisplayName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  if (authProvider.isNewUser) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'MỚI',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 8),

                              // ✅ Email với domain info
                              Column(
                                children: [
                                  Text(
                                    authProvider.currentUser?.email ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  if (authProvider.userEmailDomain.isNotEmpty)
                                    Text(
                                      'Domain: @${authProvider.userEmailDomain}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // ✅ Enhanced join date với DateTimeUtils
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tham gia ${_formatJoinDate(authProvider.currentUser?.createdAt)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ✅ ENHANCED STATISTICS với animation
                  Consumer<TodoProvider>(
                    builder: (context, todoProvider, child) {
                      return AnimatedBuilder(
                        animation: _statsAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _statsAnimation.value,
                            child: Opacity(
                              opacity: _statsAnimation.value.clamp(0.0, 1.0),
                              child: Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Thống kê công việc',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (todoProvider.stats != null)
                                            Chip(
                                              label: Text(
                                                'API',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: theme.primaryColor,
                                                ),
                                              ),
                                              backgroundColor: theme
                                                  .primaryColor
                                                  .withOpacity(0.1),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),

                                      // ✅ Enhanced stat items với gradients
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildEnhancedStatItem(
                                              icon: Icons.assignment,
                                              label: 'Tổng số',
                                              value: todoProvider.totalCount
                                                  .toString(),
                                              color: Colors.blue,
                                              theme: theme,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildEnhancedStatItem(
                                              icon: Icons.check_circle,
                                              label: 'Hoàn thành',
                                              value: todoProvider.completedCount
                                                  .toString(),
                                              color: Colors.green,
                                              theme: theme,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildEnhancedStatItem(
                                              icon: Icons.schedule,
                                              label: 'Đang làm',
                                              value: todoProvider.pendingCount
                                                  .toString(),
                                              color: Colors.orange,
                                              theme: theme,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildEnhancedStatItem(
                                              icon: Icons.warning,
                                              label: 'Quá hạn',
                                              value: todoProvider.overdueCount
                                                  .toString(),
                                              color: Colors.red,
                                              theme: theme,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      // ✅ Enhanced progress section
                                      _buildProgressSection(
                                          todoProvider, theme),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ✅ ENHANCED SETTINGS với icons và colors
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildEnhancedSettingItem(
                          icon: Icons.person,
                          title: 'Chỉnh sửa hồ sơ',
                          subtitle: 'Cập nhật thông tin cá nhân',
                          color: Colors.blue,
                          onTap: () => _navigateToEditProfile(),
                        ),
                        _buildDivider(),
                        _buildEnhancedSettingItem(
                          icon: Icons.lock,
                          title: 'Đổi mật khẩu',
                          subtitle: 'Thay đổi mật khẩu bảo mật',
                          color: Colors.orange,
                          onTap: () => _navigateToChangePassword(),
                        ),
                        _buildDivider(),
                        _buildEnhancedSettingItem(
                          icon: Icons.security,
                          title: 'Tạo mật khẩu mạnh',
                          subtitle: 'Sử dụng API tạo mật khẩu',
                          color: Colors.green,
                          onTap: () => _generateStrongPassword(),
                        ),
                        _buildDivider(),
                        _buildEnhancedSettingItem(
                          icon: Icons.notifications,
                          title: 'Thông báo',
                          subtitle: 'Cài đặt thông báo',
                          color: Colors.purple,
                          onTap: () => _showComingSoonDialog('Thông báo'),
                        ),
                        _buildDivider(),
                        _buildEnhancedSettingItem(
                          icon: Icons.help,
                          title: 'Trợ giúp & FAQ',
                          subtitle: 'Hướng dẫn sử dụng chi tiết',
                          color: Colors.teal,
                          onTap: () => _showEnhancedHelpDialog(),
                        ),
                        _buildDivider(),
                        _buildEnhancedSettingItem(
                          icon: Icons.info,
                          title: 'Về ứng dụng',
                          subtitle: 'Thông tin phiên bản & API',
                          color: Colors.indigo,
                          onTap: () => _showEnhancedAboutDialog(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ✅ ENHANCED LOGOUT BUTTON
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.1),
                            Colors.red.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.logout,
                            color: Colors.red,
                          ),
                        ),
                        title: const Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text('Thoát khỏi tài khoản hiện tại'),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.red,
                          size: 16,
                        ),
                        onTap: () => _showEnhancedLogoutDialog(),
                      ),
                    ),
                  ),

                  // ✅ DEVELOPMENT INFO (chỉ hiện trong debug mode)
                  if (kDebugMode) ...[
                    const SizedBox(height: 20),
                    _buildDevelopmentInfo(theme),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(TodoProvider todoProvider, ThemeData theme) {
    final progress = todoProvider.totalCount > 0
        ? todoProvider.completedCount / todoProvider.totalCount
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ hoàn thành',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${todoProvider.completedCount}/${todoProvider.totalCount}',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.8 ? Colors.green : theme.primaryColor,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${todoProvider.completionRate.toStringAsFixed(1)}% hoàn thành',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 68,
      endIndent: 20,
      color: Colors.grey[300],
    );
  }

  Widget _buildDevelopmentInfo(ThemeData theme) {
    return Card(
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
                  'Development Profile Info',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer2<AuthProvider, TodoProvider>(
              builder: (context, authProvider, todoProvider, child) {
                return Text(
                  'User ID: ${authProvider.currentUser?.id ?? "N/A"}\n'
                  'Auth Status: ${authProvider.isAuthenticated ? "✅" : "❌"}\n'
                  'New User: ${authProvider.isNewUser ? "✅" : "❌"}\n'
                  'Stats API: ${todoProvider.stats != null ? "✅" : "❌"}\n'
                  'API Base: https://localhost:7215',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NAVIGATION METHODS
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const EditProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ChangePasswordScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
            ),
            child: child,
          );
        },
      ),
    );
  }

  // ✅ GENERATE STRONG PASSWORD với API
  Future<void> _generateStrongPassword() async {
    LoadingDialog.show(
      context,
      message: 'Đang tạo mật khẩu mạnh...',
      canCancel: true,
    );

    try {
      final authProvider = context.read<AuthProvider>();
      final password = await authProvider.generateRandomPassword();

      if (mounted) LoadingDialog.hide(context);

      if (password != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.security, color: Colors.green),
                SizedBox(width: 8),
                Text('Mật khẩu mạnh'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mật khẩu được tạo bởi API:'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    password,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lưu ý: Hãy lưu mật khẩu này ở nơi an toàn!',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
    } catch (e) {
      if (mounted) LoadingDialog.hide(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo mật khẩu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ ENHANCED DIALOGS
  void _showEnhancedLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Đăng xuất'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn đăng xuất khỏi ứng dụng?'),
            SizedBox(height: 8),
            Text(
              'Lưu ý: Tất cả dữ liệu chưa lưu sẽ bị mất.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              print('🔓 Logout button pressed');
              Navigator.of(context).pop();

              LoadingDialog.show(
                context,
                message: 'Đang đăng xuất...',
                canCancel: false,
              );

              try {
                print('🔓 Calling AuthProvider.logout()...');
                await context.read<AuthProvider>().logout();
                print('🔓 AuthProvider.logout() completed');
                
                // Close loading dialog
                if (mounted) {
                  LoadingDialog.hide(context);
                }
              } catch (e) {
                print('❌ Logout error: $e');
                if (mounted) {
                  LoadingDialog.hide(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showEnhancedHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Colors.teal),
            SizedBox(width: 8),
            Text('Trợ giúp & FAQ'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hướng dẫn sử dụng Todo App:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildHelpItem('➕', 'Tạo công việc mới từ tab Công việc'),
              _buildHelpItem('✅', 'Nhấn checkbox để đánh dấu hoàn thành'),
              _buildHelpItem('✏️', 'Nhấn vào công việc để chỉnh sửa'),
              _buildHelpItem('🗑️', 'Vuốt sang trái để xóa công việc'),
              _buildHelpItem('📊', 'Xem thống kê tại tab Tổng quan'),
              _buildHelpItem('🔍', 'Sử dụng tìm kiếm và bộ lọc'),
              _buildHelpItem('🔐', 'Đổi mật khẩu tại Hồ sơ'),
              const SizedBox(height: 12),
              const Text(
                'API Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildHelpItem('🌐', 'Đồng bộ dữ liệu real-time'),
              _buildHelpItem('📈', 'Thống kê từ server'),
              _buildHelpItem('🔑', 'JWT Authentication'),
              _buildHelpItem('🔒', 'Mật khẩu mạnh với BCrypt'),
            ],
          ),
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

  Widget _buildHelpItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showEnhancedAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Về Todo App'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Todo App v1.0.0',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                  'Ứng dụng quản lý công việc hiệu quả với API backend mạnh mẽ.'),
              const SizedBox(height: 16),
              const Text(
                'Technology Stack:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildTechItem(
                  '📱', 'Flutter (Frontend)', 'Dart 3.0 + Material 3'),
              _buildTechItem('🔧', '.NET 8 (Backend)', 'ASP.NET Core Web API'),
              _buildTechItem('🗄️', 'MySQL (Database)', 'với Dapper ORM'),
              _buildTechItem(
                  '🔐', 'JWT Authentication', 'Bearer Token Security'),
              _buildTechItem(
                  '🔑', 'BCrypt Password', 'Strong Password Hashing'),
              const SizedBox(height: 16),
              const Text(
                'API Information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Base URL: https://localhost:7215\n'
                'Documentation: /swagger\n'
                'Health Check: /health',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
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

  Widget _buildTechItem(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.construction, color: Colors.orange),
            const SizedBox(width: 8),
            Text(feature),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Tính năng này đang được phát triển và sẽ có trong phiên bản tiếp theo.'),
            const SizedBox(height: 12),
            const Text(
              'Cảm ơn bạn đã sử dụng Todo App!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateTimeUtils.formatRelativeDate(date);
  }
}
