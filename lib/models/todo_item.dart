// lib/models/todo_item.dart
import 'package:json_annotation/json_annotation.dart';

part 'todo_item.g.dart';

@JsonSerializable()
class TodoItem {
  final int id;
  final String title;
  final String? description;
  @JsonKey(name: 'isCompleted')
  final bool isCompleted;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;
  @JsonKey(name: 'dueDate')
  final DateTime? dueDate;
  @JsonKey(name: 'userId')
  final int userId;
  @JsonKey(name: 'userName')
  final String userName;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    required this.userId,
    required this.userName,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) =>
      _$TodoItemFromJson(json);
  Map<String, dynamic> toJson() => _$TodoItemToJson(this);

  // Added copyWith method for easier state management
  TodoItem copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    int? userId,
    String? userName,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
    );
  }

  // Added getter methods for better UX
  bool get isOverdue {
    return dueDate != null && !isCompleted && DateTime.now().isAfter(dueDate!);
  }

  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  String get statusText {
    if (isCompleted) return 'Completed';
    if (isOverdue) return 'Overdue';
    if (dueDate != null && daysUntilDue <= 1) return 'Due Soon';
    return 'Pending';
  }
}

@JsonSerializable()
class CreateTodoRequest {
  final String title;
  final String? description;
  @JsonKey(name: 'dueDate')
  final DateTime? dueDate;

  CreateTodoRequest({
    required this.title,
    this.description,
    this.dueDate,
  });

  factory CreateTodoRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTodoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateTodoRequestToJson(this);
}

@JsonSerializable()
class UpdateTodoRequest {
  final String title;
  final String? description;
  @JsonKey(name: 'isCompleted')
  final bool isCompleted;
  @JsonKey(name: 'dueDate')
  final DateTime? dueDate;

  UpdateTodoRequest({
    required this.title,
    this.description,
    required this.isCompleted,
    this.dueDate,
  });

  factory UpdateTodoRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTodoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateTodoRequestToJson(this);
}

// Added TodoStats model for the stats endpoint
@JsonSerializable()
class TodoStats {
  @JsonKey(name: 'totalCount')
  final int totalCount;
  @JsonKey(name: 'completedCount')
  final int completedCount;
  @JsonKey(name: 'pendingCount')
  final int pendingCount;
  @JsonKey(name: 'overdueCount')
  final int overdueCount;
  @JsonKey(name: 'completionRate')
  final double completionRate;

  TodoStats({
    required this.totalCount,
    required this.completedCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.completionRate,
  });

  factory TodoStats.fromJson(Map<String, dynamic> json) =>
      _$TodoStatsFromJson(json);
  Map<String, dynamic> toJson() => _$TodoStatsToJson(this);
}

// Added enum for filtering todos (matches API endpoints)
enum TodoFilter {
  all, // GET /api/todoitems
  completed, // GET /api/todoitems/completed
  pending, // GET /api/todoitems/pending
  overdue // GET /api/todoitems/overdue
}

// Extension to convert enum to API endpoint
extension TodoFilterExtension on TodoFilter {
  String get endpoint {
    switch (this) {
      case TodoFilter.all:
        return '';
      case TodoFilter.completed:
        return '/completed';
      case TodoFilter.pending:
        return '/pending';
      case TodoFilter.overdue:
        return '/overdue';
    }
  }

  String get displayName {
    switch (this) {
      case TodoFilter.all:
        return 'All';
      case TodoFilter.completed:
        return 'Completed';
      case TodoFilter.pending:
        return 'Pending';
      case TodoFilter.overdue:
        return 'Overdue';
    }
  }
}

// Added helper class for todo operations
class TodoHelper {
  static const int maxTitleLength = 200;
  static const int maxDescriptionLength = 1000;

  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Tiêu đề không được để trống';
    }
    if (title.length > maxTitleLength) {
      return 'Tiêu đề không được vượt quá $maxTitleLength ký tự';
    }
    return null;
  }

  static String? validateDescription(String? description) {
    if (description != null && description.length > maxDescriptionLength) {
      return 'Mô tả không được vượt quá $maxDescriptionLength ký tự';
    }
    return null;
  }

  static bool isValidDueDate(DateTime? dueDate) {
    if (dueDate == null) return true;
    return dueDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));
  }
}
