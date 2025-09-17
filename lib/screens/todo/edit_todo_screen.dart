// lib/screens/todo/edit_todo_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';
import '../../models/todo_item.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_dialog.dart';
import '../../utils/validators.dart';
import '../../utils/date_utils.dart';
import 'add_todo_screen.dart';

class EditTodoScreen extends StatefulWidget {
  final TodoItem todo;

  const EditTodoScreen({
    super.key,
    required this.todo,
  });

  @override
  State<EditTodoScreen> createState() => _EditTodoScreenState();
}

class _EditTodoScreenState extends State<EditTodoScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isCompleted;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _hasChanges = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

    // ✅ Initialize form data
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController =
        TextEditingController(text: widget.todo.description ?? '');
    _isCompleted = widget.todo.isCompleted;
    _selectedDate = widget.todo.dueDate;

    // ✅ Extract time from due date if available
    if (widget.todo.dueDate != null) {
      _selectedTime = TimeOfDay.fromDateTime(widget.todo.dueDate!);
    }

    // Listen for changes
    _titleController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final hasFieldChanges = _titleController.text != widget.todo.title ||
        _descriptionController.text != (widget.todo.description ?? '') ||
        _isCompleted != widget.todo.isCompleted ||
        !_datesEqual(_selectedDate, widget.todo.dueDate);

    if (hasFieldChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasFieldChanges;
      });
    }
  }

  bool _datesEqual(DateTime? date1, DateTime? date2) {
    if (date1 == null && date2 == null) return true;
    if (date1 == null || date2 == null) return false;
    return DateTimeUtils.isSameDay(date1, date2) &&
        date1.hour == date2.hour &&
        date1.minute == date2.minute;
  }

  void _onCompletedChanged(bool? value) {
    setState(() {
      _isCompleted = value ?? false;
      _onFieldChanged();
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await DatePickerUtils.pickDate(
      context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _onFieldChanged();
      });

      HapticFeedback.selectionClick();
    }
  }

  Future<void> _selectTime() async {
    if (_selectedDate == null) {
      // Auto-select today if no date selected
      setState(() {
        _selectedDate = DateTime.now();
      });
    }

    final TimeOfDay? picked = await DatePickerUtils.pickTime(
      context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _onFieldChanged();
      });

      HapticFeedback.selectionClick();
    }
  }

  DateTime? get _selectedDateTime {
    if (_selectedDate == null) return null;

    final time = _selectedTime ?? const TimeOfDay(hour: 23, minute: 59);
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time.hour,
      time.minute,
    );
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _onFieldChanged();
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Có thay đổi chưa lưu'),
            content: const Text('Bạn có muốn thoát mà không lưu thay đổi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ở lại'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Thoát'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;

    LoadingDialog.show(
      context,
      message: 'Đang cập nhật công việc...',
      canCancel: false,
    );

    try {
      final todoProvider = context.read<TodoProvider>();
      final success = await todoProvider.updateTodo(
        widget.todo.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isCompleted: _isCompleted,
        dueDate: _selectedDateTime,
      );

      if (mounted) LoadingDialog.hide(context);

      if (success) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon:
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
              title: const Text('Cập nhật thành công!'),
              content: Text(
                  'Công việc "${_titleController.text.trim()}" đã được cập nhật.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context)
                        .pop(true); // Return to previous screen
                  },
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(todoProvider.error ?? 'Cập nhật thất bại');
        }
      }
    } catch (e) {
      if (mounted) LoadingDialog.hide(context);

      if (mounted) {
        _showErrorDialog('Đã xảy ra lỗi: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteTodo() async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa công việc "${widget.todo.title}"?'),
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

    if (shouldDelete == true) {
      LoadingDialog.show(
        context,
        message: 'Đang xóa công việc...',
        canCancel: false,
      );

      try {
        final todoProvider = context.read<TodoProvider>();
        final success = await todoProvider.deleteTodo(widget.todo.id);

        if (mounted) LoadingDialog.hide(context);

        if (success) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Đã xóa "${widget.todo.title}"'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            _showErrorDialog(todoProvider.error ?? 'Xóa thất bại');
          }
        }
      } catch (e) {
        if (mounted) LoadingDialog.hide(context);

        if (mounted) {
          _showErrorDialog('Lỗi khi xóa: ${e.toString()}');
        }
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
            Text('Lỗi'),
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tùy chọn',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            ListTile(
              leading: Icon(
                _isCompleted
                    ? Icons.radio_button_unchecked
                    : Icons.check_circle,
                color: _isCompleted ? Colors.grey : Colors.green,
              ),
              title: Text(_isCompleted
                  ? 'Đánh dấu chưa hoàn thành'
                  : 'Đánh dấu hoàn thành'),
              onTap: () {
                Navigator.pop(context);
                _onCompletedChanged(!_isCompleted);
              },
            ),

            ListTile(
              leading: const Icon(Icons.content_copy, color: Colors.blue),
              title: const Text('Nhân bản công việc'),
              onTap: () {
                Navigator.pop(context);
                _duplicateTodo();
              },
            ),

            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.orange),
              title: const Text('Làm mới từ server'),
              onTap: () {
                Navigator.pop(context);
                _refreshFromServer();
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Xóa công việc',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteTodo();
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _duplicateTodo() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AddTodoScreen(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo bản sao công việc'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _refreshFromServer() async {
    LoadingDialog.show(
      context,
      message: 'Đang làm mới dữ liệu...',
      canCancel: false,
    );

    try {
      final todoProvider = context.read<TodoProvider>();
      final updatedTodo = await todoProvider.getTodoDetail(widget.todo.id);

      if (mounted) LoadingDialog.hide(context);

      if (updatedTodo != null) {
        setState(() {
          _titleController.text = updatedTodo.title;
          _descriptionController.text = updatedTodo.description ?? '';
          _isCompleted = updatedTodo.isCompleted;
          _selectedDate = updatedTodo.dueDate;
          if (updatedTodo.dueDate != null) {
            _selectedTime = TimeOfDay.fromDateTime(updatedTodo.dueDate!);
          } else {
            _selectedTime = null;
          }
          _hasChanges = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật dữ liệu từ server'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) LoadingDialog.hide(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi làm mới: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = widget.todo.isOverdue && !_isCompleted;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: const Text('Chỉnh sửa công việc'),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showMoreOptions,
              tooltip: 'Tùy chọn khác',
            ),
            Consumer<TodoProvider>(
              builder: (context, todoProvider, child) {
                return TextButton(
                  onPressed:
                      todoProvider.isLoading || !_hasChanges ? null : _saveTodo,
                  child: todoProvider.isLoading
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
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ✅ STATUS INDICATORS
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade50, Colors.red.shade100],
                          ),
                          border: Border.all(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.red, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Công việc này đã quá hạn',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    DateTimeUtils.formatDueDate(
                                        widget.todo.dueDate!),
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ✅ COMPLETION STATUS CARD
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isCompleted
                                ? [Colors.green.shade50, Colors.green.shade100]
                                : [
                                    Colors.orange.shade50,
                                    Colors.orange.shade100
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Transform.scale(
                              scale: 1.2,
                              child: Checkbox(
                                value: _isCompleted,
                                onChanged: _onCompletedChanged,
                                activeColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isCompleted
                                        ? 'Đã hoàn thành'
                                        : 'Chưa hoàn thành',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _isCompleted
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                    ),
                                  ),
                                  Text(
                                    _isCompleted
                                        ? 'Tuyệt vời! Công việc đã được hoàn thành'
                                        : 'Nhấn để đánh dấu hoàn thành',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isCompleted
                                          ? Colors.green[600]
                                          : Colors.orange[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isCompleted)
                              Icon(
                                Icons.celebration,
                                color: Colors.green[600],
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ FORM FIELDS CARD
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin công việc',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ✅ TITLE FIELD
                            CustomTextField(
                              controller: _titleController,
                              labelText: 'Tiêu đề công việc *',
                              prefixIcon: Icons.title,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateTodoTitle,
                              maxLength: 200,
                            ),

                            const SizedBox(height: 16),

                            // ✅ DESCRIPTION FIELD
                            CustomTextField(
                              controller: _descriptionController,
                              labelText: 'Mô tả (tùy chọn)',
                              prefixIcon: Icons.description,
                              textInputAction: TextInputAction.done,
                              validator: Validators.validateTodoDescription,
                              maxLines: 3,
                              maxLength: 1000,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ DUE DATE CARD
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hạn hoàn thành',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Date selection
                            InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: theme.primaryColor),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ngày hạn chót',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            _selectedDate != null
                                                ? DateTimeUtils.formatFullDate(
                                                    _selectedDate!)
                                                : 'Chọn ngày (tùy chọn)',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _selectedDate != null
                                                  ? Colors.black
                                                  : Colors.grey[600],
                                              fontWeight: _selectedDate != null
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_selectedDate != null)
                                      IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.red),
                                        onPressed: _clearDate,
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Time selection (only if date is selected)
                            if (_selectedDate != null) ...[
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: _selectTime,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.schedule,
                                          color: theme.primaryColor),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Giờ hạn chót',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              _selectedTime != null
                                                  ? _selectedTime!
                                                      .format(context)
                                                  : 'Cuối ngày (23:59)',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Duration info
                            if (_selectedDateTime != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: DateTimeUtils.getDueDateColor(
                                          _selectedDateTime!, _isCompleted)
                                      .color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedDateTime!
                                              .isBefore(DateTime.now())
                                          ? Icons.warning
                                          : Icons.schedule,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateTimeUtils.formatDueDate(
                                          _selectedDateTime!),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ METADATA CARD
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin chi tiết',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildEnhancedInfoRow(
                              icon: Icons.person,
                              label: 'Người tạo',
                              value: widget.todo.userName,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            _buildEnhancedInfoRow(
                              icon: Icons.access_time,
                              label: 'Ngày tạo',
                              value: DateTimeUtils.formatRelativeDate(
                                  widget.todo.createdAt),
                              color: Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _buildEnhancedInfoRow(
                              icon: Icons.update,
                              label: 'Cập nhật lần cuối',
                              value: DateTimeUtils.formatRelativeDate(
                                  widget.todo.updatedAt),
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            _buildEnhancedInfoRow(
                              icon: Icons.tag,
                              label: 'ID',
                              value: '#${widget.todo.id}',
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ✅ DEVELOPMENT INFO (chỉ hiện trong debug mode)
                    if (kDebugMode) ...[
                      const SizedBox(height: 20),
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.code,
                                      color: Colors.blue.shade700, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Development Info',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'API Endpoint: PUT /api/todoitems/${widget.todo.id}\n'
                                'Toggle Endpoint: PATCH /api/todoitems/${widget.todo.id}/toggle\n'
                                'Delete Endpoint: DELETE /api/todoitems/${widget.todo.id}\n'
                                'Has Changes: $_hasChanges',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ✅ ACTION BUTTONS
                    Consumer<TodoProvider>(
                      builder: (context, todoProvider, child) {
                        return Column(
                          children: [
                            // Primary save button
                            CustomButton(
                              onPressed: todoProvider.isLoading || !_hasChanges
                                  ? null
                                  : _saveTodo,
                              text: 'Lưu thay đổi',
                              icon: Icons.save,
                              isLoading: todoProvider.isLoading,
                              width: double.infinity,
                              backgroundColor: theme.primaryColor,
                            ),

                            const SizedBox(height: 12),

                            // Secondary actions row
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    onPressed: todoProvider.isLoading
                                        ? null
                                        : _deleteTodo,
                                    text: 'Xóa',
                                    icon: Icons.delete,
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomButton(
                                    onPressed: todoProvider.isLoading
                                        ? null
                                        : () async {
                                            final shouldPop =
                                                await _onWillPop();
                                            if (shouldPop && mounted) {
                                              Navigator.of(context).pop();
                                            }
                                          },
                                    text: 'Hủy',
                                    icon: Icons.cancel,
                                    isOutlined: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
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

  Widget _buildEnhancedInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
