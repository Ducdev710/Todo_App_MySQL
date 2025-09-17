// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoItem _$TodoItemFromJson(Map<String, dynamic> json) => TodoItem(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      userId: (json['userId'] as num).toInt(),
      userName: json['userName'] as String,
    );

Map<String, dynamic> _$TodoItemToJson(TodoItem instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'isCompleted': instance.isCompleted,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'dueDate': instance.dueDate?.toIso8601String(),
      'userId': instance.userId,
      'userName': instance.userName,
    };

CreateTodoRequest _$CreateTodoRequestFromJson(Map<String, dynamic> json) =>
    CreateTodoRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
    );

Map<String, dynamic> _$CreateTodoRequestToJson(CreateTodoRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'dueDate': instance.dueDate?.toIso8601String(),
    };

UpdateTodoRequest _$UpdateTodoRequestFromJson(Map<String, dynamic> json) =>
    UpdateTodoRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool,
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
    );

Map<String, dynamic> _$UpdateTodoRequestToJson(UpdateTodoRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'isCompleted': instance.isCompleted,
      'dueDate': instance.dueDate?.toIso8601String(),
    };

TodoStats _$TodoStatsFromJson(Map<String, dynamic> json) => TodoStats(
      totalCount: (json['totalCount'] as num).toInt(),
      completedCount: (json['completedCount'] as num).toInt(),
      pendingCount: (json['pendingCount'] as num).toInt(),
      overdueCount: (json['overdueCount'] as num).toInt(),
      completionRate: (json['completionRate'] as num).toDouble(),
    );

Map<String, dynamic> _$TodoStatsToJson(TodoStats instance) => <String, dynamic>{
      'totalCount': instance.totalCount,
      'completedCount': instance.completedCount,
      'pendingCount': instance.pendingCount,
      'overdueCount': instance.overdueCount,
      'completionRate': instance.completionRate,
    };
