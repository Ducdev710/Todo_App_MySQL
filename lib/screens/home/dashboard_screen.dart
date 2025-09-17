// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../todo/add_todo_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _animationController.forward();

    // ✅ Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final todoProvider = context.read<TodoProvider>();

    // Load todos and stats
    await Future.wait([
      todoProvider.loadTodos(),
      todoProvider.loadStats(),
    ]);
  }

  Future<void> _refreshData() async {
    final todoProvider = context.read<TodoProvider>();

    try {
      await Future.wait([
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
                Text('Dữ liệu đã được cập nhật'),
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
        title: const Text('Tổng quan'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<TodoProvider>(
            builder: (context, todoProvider, child) {
              return IconButton(
                icon: todoProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: todoProvider.isLoading ? null : _refreshData,
                tooltip: 'Làm mới dữ liệu',
              );
            },
          ),
          // ✅ Filter button
          PopupMenuButton<TodoFilter>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc công việc',
            onSelected: (filter) {
              context.read<TodoProvider>().setFilter(filter);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TodoFilter.all,
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('Tất cả'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TodoFilter.pending,
                child: Row(
                  children: [
                    Icon(Icons.schedule),
                    SizedBox(width: 8),
                    Text('Đang làm'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TodoFilter.completed,
                child: Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Hoàn thành'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TodoFilter.overdue,
                child: Row(
                  children: [
                    Icon(Icons.warning),
                    SizedBox(width: 8),
                    Text('Quá hạn'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ ENHANCED WELCOME CARD
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        authProvider.userInitials,
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Xin chào,',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          authProvider.userDisplayName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (authProvider.isNewUser)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Thành viên mới',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Consumer<TodoProvider>(
                                builder: (context, todoProvider, child) {
                                  return Text(
                                    _getWelcomeMessage(todoProvider),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ✅ ENHANCED STATISTICS với API data
                  Consumer<TodoProvider>(
                    builder: (context, todoProvider, child) {
                      if (todoProvider.error != null) {
                        return _buildErrorCard(todoProvider);
                      }

                      return Column(
                        children: [
                          // ✅ Filter indicator
                          if (todoProvider.currentFilter != TodoFilter.all)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Card(
                                color: theme.primaryColor.withOpacity(0.1),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        todoProvider.currentFilter.icon,
                                        size: 16,
                                        color: theme.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Hiển thị: ${todoProvider.currentFilterDisplayName}',
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => todoProvider
                                            .setFilter(TodoFilter.all),
                                        child: Icon(
                                          Icons.clear,
                                          size: 16,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Statistics cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.assignment_outlined,
                                  title: 'Tổng số',
                                  value: todoProvider.totalCount.toString(),
                                  color: Colors.blue,
                                  onTap: () =>
                                      todoProvider.setFilter(TodoFilter.all),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.pending_actions_outlined,
                                  title: 'Đang làm',
                                  value: todoProvider.pendingCount.toString(),
                                  color: Colors.orange,
                                  onTap: () => todoProvider
                                      .setFilter(TodoFilter.pending),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.check_circle_outline,
                                  title: 'Hoàn thành',
                                  value: todoProvider.completedCount.toString(),
                                  color: Colors.green,
                                  onTap: () => todoProvider
                                      .setFilter(TodoFilter.completed),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.warning_amber_outlined,
                                  title: 'Quá hạn',
                                  value: todoProvider.overdueCount.toString(),
                                  color: Colors.red,
                                  onTap: () => todoProvider
                                      .setFilter(TodoFilter.overdue),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ✅ ENHANCED PROGRESS CARD với API stats
                          _buildProgressCard(todoProvider, theme),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ✅ ENHANCED RECENT TODOS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Công việc gần đây',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // Set filter to show all todos first
                          final todoProvider =
                              Provider.of<TodoProvider>(context, listen: false);
                          todoProvider.setFilter(TodoFilter.all);

                          // Navigate to todo list tab
                          try {
                            DefaultTabController.of(context).animateTo(1);
                          } catch (e) {
                            // If TabController not found, navigate manually
                            Navigator.pushNamed(context, '/todos');
                          }
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Consumer<TodoProvider>(
                    builder: (context, todoProvider, child) {
                      return _buildRecentTodos(todoProvider, theme);
                    },
                  ),

                  // ✅ DEVELOPMENT INFO (chỉ hiện trong debug mode)
                  if (kDebugMode) ...[
                    const SizedBox(height: 20),
                    _buildDevelopmentInfo(theme),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getWelcomeMessage(TodoProvider todoProvider) {
    final pending = todoProvider.pendingCount;
    final overdue = todoProvider.overdueCount;

    if (overdue > 0) {
      return 'Bạn có $overdue công việc quá hạn cần xử lý ngay!';
    } else if (pending > 0) {
      return 'Hôm nay bạn có $pending công việc cần hoàn thành';
    } else {
      return 'Tuyệt vời! Bạn đã hoàn thành tất cả công việc';
    }
  }

  Widget _buildErrorCard(TodoProvider todoProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Lỗi tải dữ liệu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              todoProvider.error!,
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomButton(
                  onPressed: () => todoProvider.refreshTodos(),
                  text: 'Thử lại',
                  icon: Icons.refresh,
                  backgroundColor: Colors.blue,
                ),
                CustomButton(
                  onPressed: () {
                    final authProvider = context.read<AuthProvider>();
                    authProvider.checkApiConnection();
                  },
                  text: 'Kiểm tra kết nối',
                  icon: Icons.network_check,
                  isOutlined: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(TodoProvider todoProvider, ThemeData theme) {
    final progress = todoProvider.totalCount > 0
        ? todoProvider.completedCount / todoProvider.totalCount
        : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tiến độ hoàn thành',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (todoProvider.stats != null)
                  Chip(
                    label: Text(
                      'API Stats',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.primaryColor,
                      ),
                    ),
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${todoProvider.completionRate.toStringAsFixed(1)}% hoàn thành',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${todoProvider.completedCount}/${todoProvider.totalCount}',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTodos(TodoProvider todoProvider, ThemeData theme) {
    final recentTodos = todoProvider.allTodos.take(5).toList();

    if (recentTodos.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có công việc nào',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy tạo công việc đầu tiên của bạn!',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              // ...existing code...
              CustomButton(
                onPressed: () {
                  // Navigate directly to add todo screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTodoScreen(),
                    ),
                  );
                },
                text: 'Tạo công việc mới',
                icon: Icons.add,
                backgroundColor: theme.primaryColor,
              ),
// ...existing code...
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentTodos.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final todo = recentTodos[index];
          return ListTile(
            leading: Checkbox(
              value: todo.isCompleted,
              onChanged: (value) {
                todoProvider.toggleTodo(todo.id);
              },
            ),
            title: Text(
              todo.title,
              style: TextStyle(
                decoration:
                    todo.isCompleted ? TextDecoration.lineThrough : null,
                color: todo.isCompleted ? Colors.grey : null,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todo.description != null)
                  Text(
                    todo.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: todo.isCompleted ? Colors.grey : null,
                    ),
                  ),
                Text(
                  'Tạo bởi: ${todo.userName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: todo.dueDate != null
                ? Chip(
                    label: Text(
                      DateTimeUtils.formatRelativeDate(todo.dueDate!),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: DateTimeUtils.getDueDateColor(
                      todo.dueDate!,
                      todo.isCompleted,
                    ),
                  )
                : todo.isOverdue
                    ? const Icon(Icons.warning, color: Colors.red, size: 20)
                    : null,
          );
        },
      ),
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
                  'Development Dashboard',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<TodoProvider>(
              builder: (context, todoProvider, child) {
                return Text(
                  'API Endpoints Used:\n'
                  '• GET /api/todoitems (loaded: ${todoProvider.allTodos.length})\n'
                  '• GET /api/todoitems/stats (${todoProvider.stats != null ? 'loaded' : 'not loaded'})\n'
                  '• Filter: ${todoProvider.currentFilter.endpoint.isEmpty ? '/api/todoitems' : '/api/todoitems${todoProvider.currentFilter.endpoint}'}\n'
                  '• Server: https://localhost:7215',
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
}

// ✅ UTILITY CLASS cho Date formatting
class DateTimeUtils {
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Ngày mai';
    } else if (difference == -1) {
      return 'Hôm qua';
    } else if (difference > 1) {
      return '${difference} ngày nữa';
    } else {
      return '${-difference} ngày trước';
    }
  }

  static Color getDueDateColor(DateTime dueDate, bool isCompleted) {
    if (isCompleted) return Colors.grey[300]!;

    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) return Colors.red[100]!; // Overdue
    if (difference == 0) return Colors.orange[100]!; // Today
    return Colors.blue[100]!; // Future
  }
}
