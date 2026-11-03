const categories = ['Breakfast', 'Lunch', 'Dinner', 'Dessert'];
const difficulties = ['Easy', 'Medium', 'Hard'];

class Validation {
  static String? email(String? input) {
    final value = (input ?? '').trim();
    if (value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? v, {bool register = false}) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (register && v.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? confirm(String? v, String password) {
    if (v == null || v.isEmpty) return 'Confirm password is required';
    return v != password ? 'Passwords do not match' : null;
  }

  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    return v.runes.length > 80 ? 'Name must be at most 80 characters' : null;
  }

  static bool whole(String v, int max) =>
      RegExp(r'^\d+$').hasMatch(v) &&
      (int.tryParse(v) ?? 0) >= 1 &&
      (int.tryParse(v) ?? max + 1) <= max;
  static String? cookTime(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Cook time is required';
    return whole(value, 600)
        ? null
        : 'Cook time must be a whole number from 1 to 600';
  }

  static String? servings(String? v) {
    final value = (v ?? '').trim();
    return value.isEmpty || whole(value, 20)
        ? null
        : 'Servings must be a whole number from 1 to 20';
  }

  static String? notes(String? v) => (v ?? '').runes.length > 300
      ? 'Notes must be at most 300 characters'
      : null;
}
