// lib/screens/todo/add_todo_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_dialog.dart';
import '../../utils/validators.dart';
import '../../utils/date_utils.dart';

class AddTodoScreen extends StatefulWidget {
  const AddTodoScreen({super.key});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;

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

    // ✅ Listen for changes to track unsaved state
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
    final hasContent = _titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _selectedDate != null;

    if (hasContent != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasContent;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await DatePickerUtils.pickDate(
      context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _onFieldChanged();
      });

      // ✅ Haptic feedback
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

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    setState(() => _isLoading = true);

    try {
      final todoProvider = Provider.of<TodoProvider>(context, listen: false);

      final success = await todoProvider.createTodo(
        title: title,
        description: description.isEmpty ? null : description,
        dueDate: _selectedDateTime,
      );

      if (success && mounted) {
        // ✅ QUAN TRỌNG: Reset loading state trước khi hiển thị dialog
        setState(() => _isLoading = false);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            title: const Text('Tạo thành công!'),
            content: Text('Công việc "${title}" đã được tạo.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Return to previous screen
                },
                child: const Text('Tiếp tục'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog

                  // Reset form state hoàn toàn
                  setState(() {
                    _titleController.clear();
                    _descriptionController.clear();
                    _selectedDate = null;
                    _selectedTime = null;
                    _hasUnsavedChanges = false;
                    _isLoading = false; // Đảm bảo loading = false
                  });

                  // Reset form validation
                  _formKey.currentState?.reset();
                },
                child: const Text('Tạo thêm'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _selectedDate = null;
      _selectedTime = null;
      _hasUnsavedChanges = false;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi tạo công việc'),
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

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Có thay đổi chưa lưu'),
            content: const Text('Bạn có muốn thoát mà không lưu công việc?'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: const Text('Thêm công việc'),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            Consumer<TodoProvider>(
              builder: (context, todoProvider, child) {
                return TextButton(
                  onPressed: todoProvider.isLoading || !_hasUnsavedChanges
                      ? null
                      : _saveTodo,
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
                            color: _hasUnsavedChanges
                                ? Colors.white
                                : Colors.white54,
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
                    // ✅ USER INFO CARD
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor.withOpacity(0.1),
                                  theme.primaryColor.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: theme.primaryColor,
                                  child: Text(
                                    authProvider.userInitials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tạo bởi: ${authProvider.userDisplayName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        DateTimeUtils.formatDateTime(
                                            DateTime.now()),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
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

                    const SizedBox(height: 20),

                    // ✅ MAIN FORM CARD
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

                            // ✅ TITLE FIELD với custom widget
                            CustomTextField(
                              controller: _titleController,
                              labelText: 'Tiêu đề công việc *',
                              prefixIcon: Icons.title,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateTodoTitle,
                              autofocus: true,
                              maxLength: 200,
                            ),

                            const SizedBox(height: 16),

                            // ✅ DESCRIPTION FIELD với custom widget
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

                            // ✅ DATE SELECTION
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
                                    Icon(
                                      Icons.calendar_today,
                                      color: theme.primaryColor,
                                    ),
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
                                        onPressed: () {
                                          setState(() {
                                            _selectedDate = null;
                                            _selectedTime = null;
                                            _onFieldChanged();
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // ✅ TIME SELECTION (only if date is selected)
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
                                      Icon(
                                        Icons.schedule,
                                        color: theme.primaryColor,
                                      ),
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
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: _selectedTime != null
                                                    ? Colors.black
                                                    : Colors.grey[600],
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

                            // ✅ DURATION INFO
                            if (_selectedDateTime != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getDurationColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getDurationColor().withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getDurationIcon(),
                                      color: _getDurationColor(),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getDurationText(),
                                      style: TextStyle(
                                        color: _getDurationColor(),
                                        fontWeight: FontWeight.w500,
                                      ),
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

                    // ✅ QUICK DATE SELECTION
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
                              'Hạn nhanh',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildQuickDateChip('Hôm nay', DateTime.now()),
                                _buildQuickDateChip(
                                  'Ngày mai',
                                  DateTime.now().add(const Duration(days: 1)),
                                ),
                                _buildQuickDateChip(
                                  'Cuối tuần',
                                  _getEndOfWeek(),
                                ),
                                _buildQuickDateChip(
                                  'Tuần sau',
                                  DateTime.now().add(const Duration(days: 7)),
                                ),
                                _buildQuickDateChip(
                                  'Tháng sau',
                                  DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month + 1,
                                    DateTime.now().day,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ✅ DEVELOPMENT INFO (chỉ hiện trong debug mode)
                    if (kDebugMode) ...[
                      const SizedBox(height: 20),
                      Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.api,
                                      color: Colors.green.shade700, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'API Integration Info',
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
                                'Endpoint: POST /api/todoitems\n'
                                'Max title: 200 chars\n'
                                'Max description: 1000 chars\n'
                                'Date format: ISO 8601 UTC',
                                style: TextStyle(
                                  color: Colors.green.shade600,
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
                            CustomButton(
                              onPressed:
                                  todoProvider.isLoading || !_hasUnsavedChanges
                                      ? null
                                      : _saveTodo,
                              text: 'Tạo công việc',
                              icon: Icons.add_task,
                              isLoading: todoProvider.isLoading,
                              width: double.infinity,
                              backgroundColor: theme.primaryColor,
                            ),
                            const SizedBox(height: 12),
                            CustomButton(
                              onPressed: todoProvider.isLoading
                                  ? null
                                  : () async {
                                      final shouldPop = await _onWillPop();
                                      if (shouldPop && mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                              text: 'Hủy',
                              icon: Icons.cancel,
                              width: double.infinity,
                              isOutlined: true,
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

  Widget _buildQuickDateChip(String label, DateTime date) {
    final isSelected =
        _selectedDate != null && DateTimeUtils.isSameDay(_selectedDate!, date);

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedDate = date;
            _selectedTime = null; // Reset time when selecting new date
          } else {
            _selectedDate = null;
            _selectedTime = null;
          }
          _onFieldChanged();
        });

        HapticFeedback.selectionClick();
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.grey[100],
    );
  }

  DateTime _getEndOfWeek() {
    final now = DateTime.now();
    final daysUntilSunday = 7 - now.weekday;
    return now.add(Duration(days: daysUntilSunday));
  }

  Color _getDurationColor() {
    if (_selectedDateTime == null) return Colors.grey;

    final duration = _selectedDateTime!.difference(DateTime.now());

    if (duration.inDays < 0) return Colors.red;
    if (duration.inDays == 0) return Colors.orange;
    if (duration.inDays <= 3) return Colors.yellow[700]!;
    return Colors.green;
  }

  IconData _getDurationIcon() {
    if (_selectedDateTime == null) return Icons.schedule;

    final duration = _selectedDateTime!.difference(DateTime.now());

    if (duration.inDays < 0) return Icons.warning;
    if (duration.inDays == 0) return Icons.today;
    if (duration.inDays <= 3) return Icons.schedule;
    return Icons.check_circle_outline;
  }

  String _getDurationText() {
    if (_selectedDateTime == null) return '';

    final duration = _selectedDateTime!.difference(DateTime.now());

    if (duration.inDays < 0) {
      return 'Thời gian đã qua';
    } else if (duration.inDays == 0) {
      if (duration.inHours > 0) {
        return 'Còn ${duration.inHours} giờ ${duration.inMinutes % 60} phút';
      } else {
        return 'Còn ${duration.inMinutes} phút';
      }
    } else {
      return 'Còn ${duration.inDays} ngày ${duration.inHours % 24} giờ';
    }
  }
}
