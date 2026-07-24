class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
    if (value.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.isEmpty) return 'Username tidak boleh kosong';
    if (value.length < 3) return 'Username minimal 3 karakter';
    if (value.length > 50) return 'Username maksimal 50 karakter';
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) return 'Username hanya boleh huruf, angka, dan underscore';
    return null;
  }
}
