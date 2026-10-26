class AppValidators {
  const AppValidators._();

  static String? name(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Name is required';
    }

    if (trimmedValue.length < 2) {
      return 'Enter a valid name';
    }

    return null;
  }

  static String? email(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Enter a valid email';
    }

    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Password is required';
    }

    if ((value ?? '').length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final confirmValue = value ?? '';

    if (confirmValue.isEmpty) {
      return 'Confirm password is required';
    }

    if (confirmValue != password) {
      return 'Passwords do not match';
    }

    return null;
  }
}
