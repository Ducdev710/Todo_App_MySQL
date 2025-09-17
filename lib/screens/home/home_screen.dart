// lib/screens/home/home_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../widgets/common/loading_dialog.dart';
import 'dashboard_screen.dart';
import 'todo_list_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _badgeAnimationController;
  late Animation<double> _badgeAnimation;

  bool _isInitialized = false;
  DateTime? _lastBackPressed;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TodoListScreen(),
    const ProfileScreen(),
  ];

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController();

    // ✅ Badge animation controller
    _badgeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _badgeAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _badgeAnimationController,
      curve: Curves.elasticOut,
    ));

    // ✅ Initialize app data
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _badgeAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // ✅ Refresh data when app resumes
        _refreshDataOnResume();
        break;
      case AppLifecycleState.paused:
        // ✅ Save state when app goes to background
        _saveAppState();
        break;
      default:
        break;
    }
  }

  // ✅ INITIALIZE APP với proper error handling
  Future<void> _initializeApp() async {
    if (_isInitialized) return;

    try {
      // ✅ Show loading for initial setup
      if (mounted) {
        LoadingDialog.show(
          context,
          message: 'Đang khởi tạo ứng dụng...',
          canCancel: false,
        );
      }

      final authProvider = context.read<AuthProvider>();
      final todoProvider = context.read<TodoProvider>();

      // ✅ Initialize auth provider first
      if (!authProvider.isInitialized) {
        await authProvider.initialize();
      }

      // ✅ Load todo data if user is authenticated
      if (authProvider.isAuthenticated) {
        await Future.wait([
          todoProvider.loadTodos(),
          todoProvider.loadStats(),
        ]);
      }

      _isInitialized = true;

      // ✅ Hide loading dialog
      if (mounted) LoadingDialog.hide(context);

      // ✅ Show welcome message for new users
      if (mounted && authProvider.isAuthenticated && authProvider.isNewUser) {
        _showWelcomeDialog();
      }
    } catch (e) {
      // ✅ Hide loading dialog on error
      if (mounted) LoadingDialog.hide(context);

      if (mounted) {
        _showInitializationError(e.toString());
      }
    }
  }

  Future<void> _refreshDataOnResume() async {
    if (!_isInitialized) return;

    final authProvider = context.read<AuthProvider>();
    final todoProvider = context.read<TodoProvider>();

    if (authProvider.isAuthenticated) {
      try {
        // ✅ Silent refresh when app resumes
        await Future.wait([
          todoProvider.refreshTodos(),
          authProvider.refreshUserData(),
        ]);

        print('🔄 Data refreshed on app resume');
      } catch (e) {
        print('❌ Failed to refresh data on resume: $e');
      }
    }
  }

  void _saveAppState() {
    // ✅ Save current state for restore
    print('💾 Saving app state...');
    // TODO: Implement state persistence if needed
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.celebration, color: Colors.blue, size: 64),
        title: const Text('Chào mừng đến với Todo App!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Xin chào ${context.read<AuthProvider>().userDisplayName}!'),
            const SizedBox(height: 12),
            const Text(
              'Hãy bắt đầu bằng cách tạo công việc đầu tiên của bạn.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Khám phá sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onTabTapped(1); // Navigate to todo list
            },
            child: const Text('Tạo công việc'),
          ),
        ],
      ),
    );
  }

  void _showInitializationError(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi khởi tạo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Không thể khởi tạo ứng dụng:'),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp(); // Retry
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // ✅ Haptic feedback
    HapticFeedback.selectionClick();

    // ✅ Trigger badge animation if there are overdue todos
    final todoProvider = context.read<TodoProvider>();
    if (index == 1 && todoProvider.overdueCount > 0) {
      _badgeAnimationController.forward().then((_) {
        _badgeAnimationController.reverse();
      });
    }
  }

  void _onTabTapped(int index) {
    // ✅ Handle double tap to refresh current screen
    if (_currentIndex == index) {
      _handleDoubleTap(index);
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleDoubleTap(int index) {
    switch (index) {
      case 0: // Dashboard
        context.read<TodoProvider>().refreshTodos();
        break;
      case 1: // Todo List
        context.read<TodoProvider>().refreshTodos();
        break;
      case 2: // Profile
        context.read<AuthProvider>().refreshUserData();
        break;
    }

    // ✅ Show refresh feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh, color: Colors.white),
            SizedBox(width: 8),
            Text('Đang làm mới...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ✅ HANDLE BACK BUTTON với double-tap to exit
  Future<bool> _onWillPop() async {
    // ✅ Try to pop current navigator first
    if (_navigatorKeys[_currentIndex].currentState?.canPop() == true) {
      _navigatorKeys[_currentIndex].currentState?.pop();
      return false;
    }

    // ✅ If on first tab, show double-tap to exit
    if (_currentIndex != 0) {
      _onTabTapped(0);
      return false;
    }

    // ✅ Double-tap to exit logic
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhấn lại để thoát ứng dụng'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true;
  }

  Widget _buildTabIcon(int index, IconData icon, IconData activeIcon) {
    final isActive = _currentIndex == index;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(
        isActive ? activeIcon : icon,
        key: ValueKey('$index-$isActive'),
      ),
    );
  }

  Widget _buildBadge(Widget child, int count) {
    if (count <= 0) return child;

    return AnimatedBuilder(
      animation: _badgeAnimation,
      builder: (context, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -6,
              top: -6,
              child: Transform.scale(
                scale: _badgeAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: count > 5 ? Colors.red : Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop) {
            SystemNavigator.pop();
          }
        }
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          body: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _screens.length,
            itemBuilder: (context, index) {
              return Navigator(
                key: _navigatorKeys[index],
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) => _screens[index],
                  );
                },
              );
            },
          ),
          bottomNavigationBar: Consumer2<TodoProvider, AuthProvider>(
            builder: (context, todoProvider, authProvider, child) {
              return Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: _onTabTapped,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: theme.primaryColor,
                  unselectedItemColor: Colors.grey[600],
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                  ),
                  backgroundColor: theme.colorScheme.surface,
                  elevation: 0,
                  items: [
                    // ✅ DASHBOARD TAB
                    BottomNavigationBarItem(
                      icon: _buildTabIcon(
                          0, Icons.dashboard_outlined, Icons.dashboard),
                      label: 'Tổng quan',
                      tooltip: 'Xem tổng quan công việc',
                    ),

                    // ✅ TODO LIST TAB với badge
                    BottomNavigationBarItem(
                      icon: _buildBadge(
                        _buildTabIcon(
                            1, Icons.checklist_outlined, Icons.checklist),
                        todoProvider.overdueCount,
                      ),
                      label: 'Công việc',
                      tooltip: todoProvider.overdueCount > 0
                          ? '${todoProvider.overdueCount} công việc quá hạn'
                          : 'Quản lý công việc',
                    ),

                    // ✅ PROFILE TAB với new user indicator
                    BottomNavigationBarItem(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildTabIcon(2, Icons.person_outlined, Icons.person),
                          if (authProvider.isNewUser)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 1),
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: 'Hồ sơ',
                      tooltip: authProvider.isNewUser
                          ? 'Thành viên mới - Xem hồ sơ'
                          : 'Xem hồ sơ cá nhân',
                    ),
                  ],
                ),
              );
            },
          ),

          // ✅ DEVELOPMENT INFO (chỉ hiện trong debug mode)
          persistentFooterButtons: kDebugMode
              ? [
                  Consumer2<AuthProvider, TodoProvider>(
                    builder: (context, authProvider, todoProvider, child) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DEBUG: Auth: ${authProvider.isAuthenticated ? "✅" : "❌"} | '
                              'Todos: ${todoProvider.totalCount} | '
                              'Overdue: ${todoProvider.overdueCount}',
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: Colors.orange.shade700,
                              ),
                            ),
                            if (todoProvider.error != null)
                              Text(
                                'Error: ${todoProvider.error}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
