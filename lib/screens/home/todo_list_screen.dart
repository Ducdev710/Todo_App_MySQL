// lib/screens/todo/todo_list_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/todo_item.dart' hide TodoFilter;
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_dialog.dart';
import '../../utils/date_utils.dart';
import '../todo/add_todo_screen.dart' as add_todo;
import '../todo/edit_todo_screen.dart' as edit_todo;

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isMultiSelectMode = false;
  final Set<int> _selectedTodos = {};
  bool _isLoading = false; // QUAN TRONG: State loading cho bulk actions

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    // ✅ FAB animation controller
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _fabAnimationController.forward();

    // ✅ Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final todoProvider = context.read<TodoProvider>();
    if (todoProvider.todoItems.isEmpty) {
      await todoProvider.loadTodos();
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    final todoProvider = context.read<TodoProvider>();
    final filter = _getFilterFromIndex(_tabController.index);

    // ✅ Use API filter endpoints
    todoProvider.setFilter(filter);

    // ✅ Haptic feedback
    HapticFeedback.selectionClick();

    // ✅ Clear search when switching tabs
    if (_isSearching) {
      _searchController.clear();
      todoProvider.searchTodos('');
    }

    // ✅ Clear multi-select mode
    if (_isMultiSelectMode) {
      _exitMultiSelectMode();
    }
  }

  TodoFilter _getFilterFromIndex(int index) {
    switch (index) {
      case 0:
        return TodoFilter.all;
      case 1:
        return TodoFilter.pending;
      case 2:
        return TodoFilter.completed;
      case 3:
        return TodoFilter.overdue;
      default:
        return TodoFilter.all;
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<TodoProvider>().searchTodos('');
      }
    });
  }

  void _enterMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = true;
      _selectedTodos.clear();
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedTodos.clear();
    });
  }

  void _toggleTodoSelection(int todoId) {
    setState(() {
      if (_selectedTodos.contains(todoId)) {
        _selectedTodos.remove(todoId);
      } else {
        _selectedTodos.add(todoId);
      }
    });
  }

  Future<void> _showSortDialog() async {
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Row(
            children: [
              Icon(Icons.sort, color: Colors.blue),
              SizedBox(width: 8),
              Text('Sắp xếp theo'),
            ],
          ),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('title_asc'),
              child: const Row(
                children: [
                  Icon(Icons.title, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Tiêu đề (A-Z)'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('title_desc'),
              child: const Row(
                children: [
                  Icon(Icons.title, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Tiêu đề (Z-A)'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('dueDate_asc'),
              child: const Row(
                children: [
                  Icon(Icons.date_range, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Hạn hoàn thành (gần nhất)'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('dueDate_desc'),
              child: const Row(
                children: [
                  Icon(Icons.date_range, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Hạn hoàn thành (xa nhất)'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('created_desc'),
              child: const Row(
                children: [
                  Icon(Icons.access_time, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Ngày tạo (mới nhất)'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('created_asc'),
              child: const Row(
                children: [
                  Icon(Icons.access_time, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Ngày tạo (cũ nhất)'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('status'),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Trạng thái'),
                ],
              ),
            ),
          ],
        ),
      );

      print('🔍 Sort result: $result');

      if (result != null && mounted) {
        final todoProvider = context.read<TodoProvider>();
        todoProvider.sortTodos(result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã sắp xếp công việc'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Sort dialog error: $e');
    }
  }

  Widget _buildSortOption(IconData icon, String title, String value) {
    return Builder(
      builder: (context) => ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        onTap: () {
          // ✅ Sử dụng context từ Builder để đảm bảo context đúng
          Navigator.of(context).pop(value);
        },
        dense: true,
      ),
    );
  }

  Future<void> _handleBulkActions() async {
    if (_selectedTodos.isEmpty) return;

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thao tác với ${_selectedTodos.length} công việc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Đánh dấu hoàn thành'),
              onTap: () => Navigator.of(context).pop('complete'),
            ),
            ListTile(
              leading: const Icon(Icons.radio_button_unchecked,
                  color: Colors.orange),
              title: const Text('Đánh dấu chưa hoàn thành'),
              onTap: () => Navigator.of(context).pop('incomplete'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa tất cả'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (action != null && mounted) {
      await _executeBulkAction(action);
    }
  }

  Future<void> _executeBulkAction(String action) async {
    final todoProvider = context.read<TodoProvider>();
    final selectedIds = _selectedTodos.toList();

    // ✅ Bỏ LoadingDialog.show() - chỉ dùng setState loading
    setState(() => _isLoading = true);

    try {
      bool success = false;

      switch (action) {
        case 'complete':
          success = await todoProvider.toggleMultipleTodos(selectedIds, true);
          break;
        case 'incomplete':
          success = await todoProvider.toggleMultipleTodos(selectedIds, false);
          break;
        case 'delete':
          success = await todoProvider.deleteMultipleTodos(selectedIds);
          break;
      }

      if (success) {
        // ✅ Reset ALL states
        setState(() {
          _selectedTodos.clear();
          _isMultiSelectMode = false;
          _isLoading = false; // QUAN TRỌNG: Reset loading state
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã xử lý ${selectedIds.length} công việc'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _isLoading = false); // Reset loading on failure

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Có lỗi xảy ra khi xử lý'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // ✅ QUAN TRỌNG: Reset loading state trong catch
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    // ✅ Bỏ LoadingDialog.hide() - chỉ dùng setState
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: _isSearching
            ? CustomTextField(
                controller: _searchController,
                labelText: 'Tìm kiếm công việc...',
                prefixIcon: Icons.search,
                autofocus: true,
                onChanged: (value) {
                  context.read<TodoProvider>().searchTodos(value);
                },
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<TodoProvider>().searchTodos('');
                  },
                ),
              )
            : _isMultiSelectMode
                ? Consumer<TodoProvider>(
                    builder: (context, todoProvider, child) {
                      final currentTodos = _getCurrentTodos(todoProvider);
                      return Text(
                          '${_selectedTodos.length}/${currentTodos.length} đã chọn');
                    },
                  )
                : const Text('Công việc'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitMultiSelectMode,
              )
            : null,
        actions: _isMultiSelectMode
            ? [
                // ✅ Thêm nút "Chọn tất cả"
                Consumer<TodoProvider>(
                  builder: (context, todoProvider, child) {
                    final currentTodos = _getCurrentTodos(todoProvider);
                    return IconButton(
                      icon: Icon(_selectedTodos.length == currentTodos.length
                          ? Icons.deselect
                          : Icons.select_all),
                      tooltip: _selectedTodos.length == currentTodos.length
                          ? 'Bỏ chọn tất cả'
                          : 'Chọn tất cả',
                      onPressed: _toggleSelectAll,
                    );
                  },
                ),
                if (_selectedTodos.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: _handleBulkActions,
                  ),
              ]
            : [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: _toggleSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortDialog,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'refresh':
                        context.read<TodoProvider>().refreshTodos();
                        break;
                      case 'select':
                        _enterMultiSelectMode();
                        break;
                      case 'stats':
                        _showStatsDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Làm mới'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(Icons.checklist),
                          SizedBox(width: 8),
                          Text('Chọn nhiều'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'stats',
                      child: Row(
                        children: [
                          Icon(Icons.analytics),
                          SizedBox(width: 8),
                          Text('Thống kê'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: [
            Consumer<TodoProvider>(
              builder: (context, todoProvider, child) {
                return Tab(
                  child: _buildTabWithBadge(
                    'Tất cả',
                    todoProvider.totalCount,
                    Colors.blue,
                  ),
                );
              },
            ),
            Consumer<TodoProvider>(
              builder: (context, todoProvider, child) {
                return Tab(
                  child: _buildTabWithBadge(
                    'Đang làm',
                    todoProvider.pendingCount,
                    Colors.orange,
                  ),
                );
              },
            ),
            Consumer<TodoProvider>(
              builder: (context, todoProvider, child) {
                return Tab(
                  child: _buildTabWithBadge(
                    'Hoàn thành',
                    todoProvider.completedCount,
                    Colors.green,
                  ),
                );
              },
            ),
            Consumer<TodoProvider>(
              builder: (context, todoProvider, child) {
                return Tab(
                  child: _buildTabWithBadge(
                    'Quá hạn',
                    todoProvider.overdueCount,
                    Colors.red,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          if (todoProvider.error != null) {
            return _buildErrorWidget(todoProvider);
          }

          return RefreshIndicator(
            onRefresh: () => todoProvider.refreshTodos(),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodoList(todoProvider.filteredTodos, todoProvider),
                _buildTodoList(todoProvider.filteredTodos, todoProvider),
                _buildTodoList(todoProvider.filteredTodos, todoProvider),
                _buildTodoList(todoProvider.filteredTodos, todoProvider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: () => _navigateToAddTodo(),
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Tạo mới'),
              ),
            ),
    );
  }

  Widget _buildTabWithBadge(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTodoList(List<TodoItem> todos, TodoProvider todoProvider) {
    // ✅ Sử dụng filteredTodos thay vì parameter todos
    final displayTodos = todoProvider.filteredTodos;

    if (todoProvider.isLoading && displayTodos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (displayTodos.isEmpty) {
      return _buildEmptyWidget();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: displayTodos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final todo = displayTodos[index];
        return _buildTodoCard(todo);
      },
    );
  }

  Widget _buildTodoCard(TodoItem todo) {
    final isSelected = _selectedTodos.contains(todo.id);

    return Dismissible(
      key: Key('todo_${todo.id}'),
      direction: _isMultiSelectMode
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 24),
            Text('Xóa', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (direction) => _confirmDelete(todo),
      onDismissed: (direction) => _deleteTodo(todo),
      child: Card(
        elevation: isSelected ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).primaryColor
                : todo.isOverdue && !todo.isCompleted
                    ? Colors.red
                    : Colors.transparent,
            width:
                isSelected ? 2 : (todo.isOverdue && !todo.isCompleted ? 1 : 0),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleTodoTap(todo),
          onLongPress: () => _handleTodoLongPress(todo),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_isMultiSelectMode)
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleTodoSelection(todo.id),
                        )
                      else
                        Checkbox(
                          value: todo.isCompleted,
                          onChanged: (value) => _toggleTodo(todo),
                          activeColor: Colors.green,
                        ),
                      Expanded(
                        child: Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: todo.isCompleted ? Colors.grey : null,
                          ),
                        ),
                      ),
                      if (todo.isOverdue && !todo.isCompleted) ...[
                        const Icon(Icons.warning, color: Colors.red, size: 20),
                        const SizedBox(width: 4),
                      ],
                      if (todo.isCompleted)
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                    ],
                  ),
                  if (todo.description != null &&
                      todo.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      todo.description!,
                      style: TextStyle(
                        color:
                            todo.isCompleted ? Colors.grey : Colors.grey[600],
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (todo.dueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: DateTimeUtils.getDueDateColor(
                                    todo.dueDate!, todo.isCompleted)
                                .color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                DateTimeUtils.formatDueDate(todo.dueDate!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Tạo: ${DateTimeUtils.formatRelativeDate(todo.createdAt)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            'Bởi: ${todo.userName}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTodoTap(TodoItem todo) {
    if (_isMultiSelectMode) {
      _toggleTodoSelection(todo.id);
    } else {
      _navigateToEditTodo(todo);
    }
  }

  void _handleTodoLongPress(TodoItem todo) {
    if (!_isMultiSelectMode) {
      _enterMultiSelectMode();
      _toggleTodoSelection(todo.id);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _toggleTodo(TodoItem todo) async {
    await context.read<TodoProvider>().toggleTodo(todo.id);
  }

  Future<bool?> _confirmDelete(TodoItem todo) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa công việc "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTodo(TodoItem todo) async {
    final success = await context.read<TodoProvider>().deleteTodo(todo.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Đã xóa "${todo.title}"' : 'Lỗi khi xóa "${todo.title}"',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildEmptyWidget() {
    final currentFilter = context.watch<TodoProvider>().currentFilter;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(currentFilter),
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyTitle(currentFilter),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptySubtitle(currentFilter),
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (currentFilter == TodoFilter.all) ...[
              const SizedBox(height: 24),
              CustomButton(
                onPressed: () => _navigateToAddTodo(),
                text: 'Tạo công việc đầu tiên',
                icon: Icons.add,
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getEmptyIcon(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return Icons.assignment_outlined;
      case TodoFilter.pending:
        return Icons.schedule;
      case TodoFilter.completed:
        return Icons.check_circle_outline;
      case TodoFilter.overdue:
        return Icons.warning_amber_outlined;
    }
  }

  String _getEmptyTitle(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return 'Chưa có công việc nào';
      case TodoFilter.pending:
        return 'Không có công việc đang làm';
      case TodoFilter.completed:
        return 'Chưa hoàn thành công việc nào';
      case TodoFilter.overdue:
        return 'Không có công việc quá hạn';
    }
  }

  String _getEmptySubtitle(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return 'Nhấn nút + để tạo công việc mới';
      case TodoFilter.pending:
        return 'Tất cả công việc đã hoàn thành hoặc quá hạn';
      case TodoFilter.completed:
        return 'Hãy hoàn thành một số công việc!';
      case TodoFilter.overdue:
        return 'Tuyệt vời! Không có công việc nào quá hạn';
    }
  }

  Widget _buildErrorWidget(TodoProvider todoProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
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
            const SizedBox(height: 24),
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

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          final stats = todoProvider.stats;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text('Thống kê công việc'),
              ],
            ),
            content: stats != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatRow('Tổng số:', stats.totalCount.toString()),
                      _buildStatRow(
                          'Hoàn thành:', stats.completedCount.toString()),
                      _buildStatRow('Đang làm:', stats.pendingCount.toString()),
                      _buildStatRow('Quá hạn:', stats.overdueCount.toString()),
                      const Divider(),
                      _buildStatRow(
                        'Tỷ lệ hoàn thành:',
                        '${stats.completionRate.toStringAsFixed(1)}%',
                      ),
                    ],
                  )
                : const Text('Không có dữ liệu thống kê'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTodo() async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const add_todo.AddTodoScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(0.0, 1.0), end: Offset.zero),
            ),
            child: child,
          );
        },
      ),
    );

    if (result == true && mounted) {
      context.read<TodoProvider>().refreshTodos();
    }
  }

  void _navigateToEditTodo(TodoItem todo) async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            edit_todo.EditTodoScreen(todo: todo),
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

    if (result == true && mounted) {
      context.read<TodoProvider>().refreshTodos();
    }
  }

  // ✅ Lấy danh sách todos hiện tại theo tab
  List<TodoItem> _getCurrentTodos(TodoProvider todoProvider) {
    return todoProvider.filteredTodos;
  }

  // ✅ Chọn/bỏ chọn tất cả todos
  void _toggleSelectAll() {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    setState(() {
      final currentTodos = _getCurrentTodos(todoProvider);

      if (_selectedTodos.length == currentTodos.length) {
        // Nếu đã chọn tất cả -> bỏ chọn tất cả
        _selectedTodos.clear();
      } else {
        // Chưa chọn tất cả -> chọn tất cả
        _selectedTodos.clear();
        _selectedTodos.addAll(currentTodos.map((todo) => todo.id));
      }
    });

    // Haptic feedback
    HapticFeedback.selectionClick();
  }
}

class _SortOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SortOption(this.icon, this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        onTap: () {
          // ✅ Sử dụng context từ Builder để đảm bảo context đúng
          Navigator.of(context).pop(value);
        },
        dense: true,
      ),
    );
  }
}
