// lib/models/user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String name;
  final String email;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String name;
  final String email;
  final String password;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final String token;
  final User user;
  @JsonKey(name: 'expires') // Changed from 'expireAt' to 'expires'
  final DateTime expires;

  AuthResponse({
    required this.token,
    required this.user,
    required this.expires,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

// ✅ CHANGE PASSWORD REQUEST - Updated to match API
@JsonSerializable()
class ChangePasswordRequest {
  @JsonKey(name: 'currentPassword')
  final String currentPassword;
  @JsonKey(name: 'newPassword')
  final String newPassword;
  @JsonKey(name: 'confirmNewPassword') // Changed to match API
  final String confirmNewPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);
}

// ✅ CHANGE PASSWORD RESPONSE - New model for API response
@JsonSerializable()
class ChangePasswordResponse {
  final String message;
  @JsonKey(name: 'changedAt')
  final DateTime changedAt;

  ChangePasswordResponse({
    required this.message,
    required this.changedAt,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePasswordResponseToJson(this);
}

// ✅ UPDATE PROFILE REQUEST - Not directly supported in API, but useful for UI
class UpdateProfileRequest {
  final String name;
  final String email;

  UpdateProfileRequest({
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
      };

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) =>
      UpdateProfileRequest(
        name: json['name'] as String,
        email: json['email'] as String,
      );
}
