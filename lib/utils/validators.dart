// lib/utils/validators.dart
class Validators {
  // ✅ EMAIL VALIDATION
  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Vui lòng nhập email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  static String? validateEmailForRegister(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Vui lòng nhập email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Email không đúng định dạng';
    }
    if (value.length > 255) {
      return 'Email không được vượt quá 255 ký tự';
    }
    return null;
  }

  // ✅ PASSWORD VALIDATION
  static String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value!.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  // ✅ STRONG PASSWORD VALIDATION (theo API requirements)
  static String? validateStrongPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value!.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }

    // Check for uppercase, lowercase, digit, and special character
    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = value.contains(RegExp(r'[a-z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters =
        value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase || !hasLowercase || !hasDigits || !hasSpecialCharacters) {
      return 'Mật khẩu phải có chữ hoa, chữ thường, số và ký tự đặc biệt';
    }

    if (value.length > 100) {
      return 'Mật khẩu không được vượt quá 100 ký tự';
    }

    return null;
  }

  // ✅ CONFIRM PASSWORD VALIDATION
  static String? validateConfirmPassword(String? value, String password) {
    if (value?.isEmpty ?? true) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  // ✅ NAME VALIDATION
  static String? validateName(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value!.trim().length < 2) {
      return 'Tên phải có ít nhất 2 ký tự';
    }
    if (value.length > 100) {
      return 'Tên không được vượt quá 100 ký tự';
    }
    return null;
  }

  // ✅ TODO TITLE VALIDATION
  static String? validateTodoTitle(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Vui lòng nhập tiêu đề';
    }
    if (value!.trim().length < 1) {
      return 'Tiêu đề không được để trống';
    }
    if (value.length > 200) {
      return 'Tiêu đề không được vượt quá 200 ký tự';
    }
    return null;
  }

  // ✅ TODO DESCRIPTION VALIDATION
  static String? validateTodoDescription(String? value) {
    if (value != null && value.length > 1000) {
      return 'Mô tả không được vượt quá 1000 ký tự';
    }
    return null;
  }

  // ✅ REQUIRED FIELD VALIDATION
  static String? validateRequired(String? value, String fieldName) {
    if (value?.isEmpty ?? true) {
      return 'Vui lòng nhập $fieldName';
    }
    return null;
  }

  // ✅ PHONE NUMBER VALIDATION
  static String? validatePhoneNumber(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Vui lòng nhập số điện thoại';
    }
    if (!RegExp(r'^[0-9+\-\s\(\)]+$').hasMatch(value!)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  // ✅ URL VALIDATION
  static String? validateUrl(String? value) {
    if (value?.isEmpty ?? true) {
      return null; // Optional field
    }
    
    final uri = Uri.tryParse(value!);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'URL không hợp lệ';
    }
    
    return null;
  }

  // ✅ NUMBER VALIDATION
  static String? validateNumber(String? value, {int? min, int? max}) {
    if (value?.isEmpty ?? true) {
      return 'Vui lòng nhập số';
    }

    final number = int.tryParse(value!);
    if (number == null) {
      return 'Vui lòng nhập số hợp lệ';
    }

    if (min != null && number < min) {
      return 'Số phải lớn hơn hoặc bằng $min';
    }

    if (max != null && number > max) {
      return 'Số phải nhỏ hơn hoặc bằng $max';
    }

    return null;
  }

  // ✅ DATE VALIDATION
  static String? validateDate(String? value) {
    if (value?.isEmpty ?? true) {
      return null; // Optional field
    }

    try {
      DateTime.parse(value!);
      return null;
    } catch (e) {
      return 'Ngày không hợp lệ';
    }
  }

  // ✅ PASSWORD STRENGTH CHECK
  static bool isPasswordStrong(String password) {
    if (password.length < 8) return false;

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
  }

  // ✅ PASSWORD STRENGTH SCORE (0-4)
  static int getPasswordStrengthScore(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    return score;
  }

  // ✅ PASSWORD STRENGTH TEXT
  static String getPasswordStrengthText(String password) {
    int score = getPasswordStrengthScore(password);

    switch (score) {
      case 0:
      case 1:
        return 'Rất yếu';
      case 2:
        return 'Yếu';
      case 3:
        return 'Trung bình';
      case 4:
        return 'Mạnh';
      case 5:
        return 'Rất mạnh';
      default:
        return 'Chưa đánh giá';
    }
  }
}
