
class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );
  
  static final RegExp _phoneRegExp = RegExp(
    r'^[0-9]{10}$',
  );

  static final RegExp _usernameRegExp = RegExp(
    r'^[a-zA-Z0-9._]+$',
  );

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return null; // Allow empty if optional? No, usually required checks separate
    if (!_emailRegExp.hasMatch(value)) {
      return 'Invalid email address';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!_phoneRegExp.hasMatch(value)) {
      return 'Phone number must be 10 digits';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 4) return 'Min 4 characters';
    if (!_usernameRegExp.hasMatch(value)) {
      return 'Alphanumeric only (dot/underscore allowed)';
    }
    return null;
  }

  static String? minLength(String? value, int min) {
    if (value == null || value.isEmpty) return null;
    if (value.length < min) {
      return 'Min $min characters required';
    }
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    final n = double.tryParse(value);
    if (n == null) return 'Invalid number';
    if (n <= 0) return 'Must be positive';
    return null;
  }

  static String? nonNegativeNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    final n = double.tryParse(value);
    if (n == null) return 'Invalid number';
    if (n < 0) return 'Must be non-negative';
    return null;
  }
}
