// lib/providers/todo_provider.dart
import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../services/api_service.dart' as api;

enum TodoFilter { all, pending, completed, overdue }

class TodoProvider with ChangeNotifier {
  final api.ApiService _apiService = api.ApiService();

  List<TodoItem> _todoItems = [];
  List<TodoItem> _filteredTodos = [];
  api.TodoStats? _stats;
  bool _isLoading = false;
  String? _error;
  TodoFilter _currentFilter = TodoFilter.all;

  // Getters
  List<TodoItem> get todoItems => _todoItems; // All todos (unfiltered)
  List<TodoItem> get filteredTodos => _filteredTodos; // Filtered todos for UI
  List<TodoItem> get allTodos => _todoItems; // Alias for backward compatibility
  api.TodoStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TodoFilter get currentFilter => _currentFilter;

  // ✅ COMPUTED PROPERTIES từ local data (fast access)
  List<TodoItem> get pendingTodos =>
      _todoItems.where((todo) => !todo.isCompleted).toList();
  List<TodoItem> get completedTodos =>
      _todoItems.where((todo) => todo.isCompleted).toList();
  List<TodoItem> get overdueTodos => _todoItems
      .where((todo) =>
          !todo.isCompleted &&
          todo.dueDate != null &&
          todo.dueDate!.isBefore(DateTime.now()))
      .toList();

  // ✅ STATS từ API hoặc computed từ local data
  int get totalCount => _stats?.totalCount ?? _todoItems.length;
  int get pendingCount => _stats?.pendingCount ?? pendingTodos.length;
  int get completedCount => _stats?.completedCount ?? completedTodos.length;
  int get overdueCount => _stats?.overdueCount ?? overdueTodos.length;
  double get completionRate => _stats?.completionRate ?? 
      (totalCount > 0 ? (completedCount / totalCount) * 100 : 0);

  // ================================
  // CORE METHODS - Updated cho API endpoints
  // ================================

  // ✅ LOAD TODOS - Có thể load từ filter-specific endpoints
  Future<void> loadTodos({TodoFilter? filter}) async {
    _setLoading(true);
    _setError(null);

    try {
      filter ??= _currentFilter;

      // ✅ SỬ DỤNG FILTER-SPECIFIC ENDPOINTS của API
      switch (filter) {
        case TodoFilter.all:
          _todoItems = await _apiService.getAllTodoItems();
          break;
        case TodoFilter.completed:
          _todoItems = await _apiService.getCompletedTodoItems();
          break;
        case TodoFilter.pending:
          _todoItems = await _apiService.getPendingTodoItems();
          break;
        case TodoFilter.overdue:
          _todoItems = await _apiService.getOverdueTodoItems();
          break;
      }

      _currentFilter = filter;
      _applyFilter();

      // ✅ Load stats từ API endpoint riêng
      await loadStats();

      print('✅ Loaded ${_todoItems.length} todos with filter: $filter');
    } catch (e) {
      print('❌ Load todos error: $e');
      _setError(_parseErrorMessage(e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  // ✅ REFRESH TODOS - Load lại với filter hiện tại
  Future<void> refreshTodos() async {
    await loadTodos(filter: _currentFilter);
  }

  // ✅ CREATE TODO - Validation theo API requirements
  Future<bool> createTodo({
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    // ✅ Validation theo API constraints
    if (title.trim().isEmpty) {
      _setError('Tiêu đề không được để trống');
      return false;
    }

    if (title.trim().length > 200) {
      _setError('Tiêu đề không được vượt quá 200 ký tự');
      return false;
    }

    if (description != null && description.trim().length > 1000) {
      _setError('Mô tả không được vượt quá 1000 ký tự');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      print('🚀 Creating todo: ${title.trim()}');

      final newTodo = await _apiService.createTodoItem(
        title.trim(),
        description?.trim().isEmpty == true ? null : description?.trim(),
        dueDate,
      );

      // ✅ Thêm vào local list nếu phù hợp với filter hiện tại
      if (_shouldIncludeInCurrentFilter(newTodo)) {
        _todoItems.insert(0, newTodo);
        _applyFilter();
      }

      await loadStats();

      print('✅ Todo created successfully: ${newTodo.title}');
      return true;
    } catch (e) {
      print('❌ Create todo error: $e');
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ UPDATE TODO - Full update với validation
  Future<bool> updateTodo(
    int id, {
    required String title,
    String? description,
    required bool isCompleted,
    DateTime? dueDate,
  }) async {
    // ✅ Validation theo API constraints
    if (title.trim().isEmpty) {
      _setError('Tiêu đề không được để trống');
      return false;
    }

    if (title.trim().length > 200) {
      _setError('Tiêu đề không được vượt quá 200 ký tự');
      return false;
    }

    if (description != null && description.trim().length > 1000) {
      _setError('Mô tả không được vượt quá 1000 ký tự');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      print('🚀 Updating todo $id: title=$title, completed=$isCompleted');

      await _apiService.updateTodoItem(
        id,
        title.trim(),
        description?.trim().isEmpty == true ? null : description?.trim(),
        isCompleted,
        dueDate,
      );

      // ✅ Update local list với copyWith method
      final index = _todoItems.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todoItems[index] = _todoItems[index].copyWith(
          title: title.trim(),
          description: description?.trim(),
          isCompleted: isCompleted,
          updatedAt: DateTime.now(),
          dueDate: dueDate,
        );
      }

      _applyFilter();
      await loadStats();

      print('✅ Todo updated successfully');
      return true;
    } catch (e) {
      print('❌ Update todo error: $e');
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ TOGGLE TODO - Sử dụng API endpoint riêng
  Future<bool> toggleTodo(int id) async {
    _setLoading(true);
    _setError(null);

    try {
      print('🚀 Toggling todo $id');

      await _apiService.toggleTodoItem(id);

      // ✅ Update local list
      final index = _todoItems.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todoItems[index] = _todoItems[index].copyWith(
          isCompleted: !_todoItems[index].isCompleted,
          updatedAt: DateTime.now(),
        );
      }

      _applyFilter();
      await loadStats();

      print('✅ Todo toggled successfully');
      return true;
    } catch (e) {
      print('❌ Toggle todo error: $e');
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ DELETE TODO
  Future<bool> deleteTodo(int id) async {
    _setLoading(true);
    _setError(null);

    try {
      print('🚀 Deleting todo $id');

      await _apiService.deleteTodoItem(id);

      _todoItems.removeWhere((todo) => todo.id == id);
      _applyFilter();
      await loadStats();

      print('✅ Todo deleted successfully');
      return true;
    } catch (e) {
      print('❌ Delete todo error: $e');
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ LOAD STATS - Sử dụng API endpoint /stats
  Future<void> loadStats() async {
    try {
      print('🚀 Loading todo stats');

      _stats = await _apiService.getTodoStats();
      notifyListeners();

      print('✅ Stats loaded: ${_stats?.toJson()}');
    } catch (e) {
      print('❌ Failed to load stats: $e');
      // Don't show error to user, stats are not critical
    }
  }

  // ✅ GET TODO DETAIL - Sử dụng API endpoint riêng
  Future<TodoItem?> getTodoDetail(int id) async {
    try {
      print('🚀 Getting todo detail for id: $id');

      final todo = await _apiService.getTodoItem(id);

      // ✅ Update local cache nếu có
      final index = _todoItems.indexWhere((t) => t.id == id);
      if (index != -1) {
        _todoItems[index] = todo;
        _applyFilter();
      }

      print('✅ Todo detail loaded: ${todo.title}');
      return todo;
    } catch (e) {
      print('❌ Get todo detail error: $e');
      _setError(_parseErrorMessage(e.toString()));
      return null;
    }
  }

  // ================================
  // FILTER METHODS - Updated cho API
  // ================================

  // ✅ SET FILTER - Load data từ API cho filter mới
  Future<void> setFilter(TodoFilter filter) async {
    if (_currentFilter != filter) {
      print('🔄 Switching filter from $_currentFilter to $filter');

      // ✅ Nếu có internet, load từ API endpoint tương ứng
      try {
        await loadTodos(filter: filter);
      } catch (e) {
        // ✅ Fallback: filter local data nếu API fail
        print('🔧 API filter failed, using local filter: $e');
        _currentFilter = filter;
        _applyFilter();
      }
    }
  }

  // ✅ APPLY LOCAL FILTER (fallback hoặc offline mode)
  void _applyFilter() {
    switch (_currentFilter) {
      case TodoFilter.all:
        _filteredTodos = List.from(_todoItems);
        break;
      case TodoFilter.pending:
        _filteredTodos = _todoItems.where((todo) => !todo.isCompleted).toList();
        break;
      case TodoFilter.completed:
        _filteredTodos = _todoItems.where((todo) => todo.isCompleted).toList();
        break;
      case TodoFilter.overdue:
        _filteredTodos = _todoItems.where((todo) => todo.isOverdue).toList();
        break;
    }
    notifyListeners();
  }

  // ✅ CHECK IF TODO SHOULD BE INCLUDED IN CURRENT FILTER
  bool _shouldIncludeInCurrentFilter(TodoItem todo) {
    switch (_currentFilter) {
      case TodoFilter.all:
        return true;
      case TodoFilter.pending:
        return !todo.isCompleted;
      case TodoFilter.completed:
        return todo.isCompleted;
      case TodoFilter.overdue:
        return todo.isOverdue;
    }
  }

  // ================================
  // SEARCH & SORT - Enhanced
  // ================================

  void searchTodos(String query) {
    if (query.trim().isEmpty) {
      _applyFilter();
      return;
    }

    final searchQuery = query.toLowerCase().trim();
    _filteredTodos = _getCurrentFilteredList()
        .where((todo) =>
            todo.title.toLowerCase().contains(searchQuery) ||
            (todo.description?.toLowerCase().contains(searchQuery) ?? false) ||
            todo.userName.toLowerCase().contains(searchQuery))
        .toList();

    notifyListeners();
  }

  // ✅ SORT TODOS METHOD - với debug logging
  void sortTodos(String sortBy) {
    try {
      print('🔄 Sorting todos by: $sortBy');
      print('🔍 Before sort - filteredTodos count: ${_filteredTodos.length}');
      
      // ✅ Sort trực tiếp _filteredTodos, không cần copy phức tạp
      switch (sortBy) {
        case 'title_asc':
          _filteredTodos.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          print('✅ Sorted by title ascending');
          break;
        case 'title_desc':
          _filteredTodos.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
          print('✅ Sorted by title descending');
          break;
        case 'dueDate_asc':
          _filteredTodos.sort((a, b) {
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });
          print('✅ Sorted by due date ascending');
          break;
        case 'dueDate_desc':
          _filteredTodos.sort((a, b) {
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return b.dueDate!.compareTo(a.dueDate!);
          });
          print('✅ Sorted by due date descending');
          break;
        case 'created_desc':
          _filteredTodos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          print('✅ Sorted by created date descending');
          break;
        case 'created_asc':
          _filteredTodos.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          print('✅ Sorted by created date ascending');
          break;
        case 'status':
          _filteredTodos.sort((a, b) {
            // Chưa hoàn thành lên trước
            if (a.isCompleted == b.isCompleted) return 0;
            return a.isCompleted ? 1 : -1;
          });
          print('✅ Sorted by status');
          break;
        default:
          print('❌ Unknown sort type: $sortBy');
          return;
      }

      print('🔍 After sort - filteredTodos count: ${_filteredTodos.length}');
      
      // ✅ Chỉ notify listeners, không làm gì khác
      notifyListeners();
      print('✅ Sort completed successfully and listeners notified');
      
    } catch (e) {
      print('❌ Sort error: $e');
      _setError('Lỗi sắp xếp: ${e.toString()}');
    }
  }

  List<TodoItem> _getCurrentFilteredList() {
    switch (_currentFilter) {
      case TodoFilter.all:
        return _todoItems;
      case TodoFilter.pending:
        return _todoItems.where((todo) => !todo.isCompleted).toList();
      case TodoFilter.completed:
        return _todoItems.where((todo) => todo.isCompleted).toList();
      case TodoFilter.overdue:
        return _todoItems.where((todo) => todo.isOverdue).toList();
    }
  }

  // ================================
  // UTILITY METHODS - Enhanced
  // ================================

  TodoItem? getTodoById(int id) {
    try {
      return _todoItems.firstWhere((todo) => todo.id == id);
    } catch (e) {
      return null;
    }
  }

  // ✅ BULK OPERATIONS
  Future<bool> toggleMultipleTodos(List<int> ids, bool isCompleted) async {
    if (ids.isEmpty) return false;

    _setLoading(true);
    _setError(null);

    try {
      // ✅ Process in batches to avoid overwhelming the server
      final results = <bool>[];

      for (final id in ids) {
        try {
          if (isCompleted) {
            final todo = getTodoById(id);
            if (todo != null && !todo.isCompleted) {
              await _apiService.toggleTodoItem(id);
              results.add(true);
            }
          } else {
            final todo = getTodoById(id);
            if (todo != null && todo.isCompleted) {
              await _apiService.toggleTodoItem(id);
              results.add(true);
            }
          }
        } catch (e) {
          print('❌ Failed to toggle todo $id: $e');
          results.add(false);
        }
      }

      // ✅ Refresh data after bulk operations
      await loadTodos();

      final successCount = results.where((r) => r).length;
      print('✅ Bulk toggle completed: $successCount/${ids.length} successful');

      return successCount > 0;
    } catch (e) {
      print('❌ Bulk toggle error: $e');
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteMultipleTodos(List<int> ids) async {
    if (ids.isEmpty) return false;

    _setLoading(true);
    _setError(null);

    try {
      final results = <bool>[];

      for (final id in ids) {
        try {
          await _apiService.deleteTodoItem(id);
          results.add(true);
        } catch (e) {
          print('❌ Failed to delete todo $id: $e');
          results.add(false);
        }
      }

      // ✅ Refresh data after bulk operations
      await loadTodos();

      final successCount = results.where((r) => r).length;
      print('✅ Bulk delete completed: $successCount/${ids.length} successful');

      return successCount > 0;
    } catch (e) {
      print('❌ Bulk delete error: $e');
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ RESET STATE
  void resetState() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ================================
  // PRIVATE HELPER METHODS
  // ================================

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  // ✅ ENHANCED ERROR PARSING với API-specific errors
  String _parseErrorMessage(String error) {
    String cleanError = error.replaceFirst('Exception: ', '');

    // ✅ Handle specific API error patterns
    if (cleanError.contains('TODOITEM_NOT_FOUND') ||
        cleanError.contains('Todo item') && cleanError.contains('not found')) {
      return 'Không tìm thấy công việc này. Có thể đã bị xóa.';
    } else if (cleanError.contains('VALIDATION_ERROR') ||
        cleanError.contains('Tiêu đề không được để trống')) {
      return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
    } else if (cleanError.contains('UNAUTHORIZED') ||
        cleanError.contains('Unauthorized')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    } else if (cleanError.contains('FORBIDDEN') ||
        cleanError.contains('Forbidden')) {
      return 'Bạn không có quyền thực hiện hành động này.';
    } else if (cleanError.contains('CONNECTION_REFUSED') ||
        cleanError.contains('SocketException')) {
      return 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
    } else if (cleanError.contains('TIMEOUT')) {
      return 'Kết nối quá chậm. Vui lòng thử lại.';
    } else if (cleanError.contains('Server Error') ||
        cleanError.contains('500') ||
        cleanError.contains('INTERNAL_SERVER_ERROR')) {
      return 'Lỗi máy chủ. Vui lòng thử lại sau.';
    } else if (cleanError.contains('Network') ||
        cleanError.contains('connection')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
    }

    return cleanError.isEmpty ? 'Đã xảy ra lỗi không xác định' : cleanError;
  }

  // ✅ GETTER cho filter display name
  String get currentFilterDisplayName {
    return _currentFilter.displayName;
  }

  // ✅ CHECK nếu có pending changes (để show unsaved warning)
  bool get hasPendingChanges {
    // Implement logic to track unsaved changes if needed
    return false;
  }
}

// ✅ EXTENSION cho TodoFilter
extension TodoFilterExtension on TodoFilter {
  String get displayName {
    switch (this) {
      case TodoFilter.all:
        return 'Tất cả';
      case TodoFilter.pending:
        return 'Đang làm';
      case TodoFilter.completed:
        return 'Hoàn thành';
      case TodoFilter.overdue:
        return 'Quá hạn';
    }
  }

  String get endpoint {
    switch (this) {
      case TodoFilter.all:
        return '';
      case TodoFilter.pending:
        return '/pending';
      case TodoFilter.completed:
        return '/completed';
      case TodoFilter.overdue:
        return '/overdue';
    }
  }

  IconData get icon {
    switch (this) {
      case TodoFilter.all:
        return Icons.list;
      case TodoFilter.pending:
        return Icons.schedule;
      case TodoFilter.completed:
        return Icons.check_circle;
      case TodoFilter.overdue:
        return Icons.warning;
    }
  }
}
