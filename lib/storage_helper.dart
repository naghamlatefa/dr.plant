import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static const _kName = 'user_name';
  static const _kEmail = 'user_email';
  static const _kPhone = 'user_phone';

  static Future<void> saveUserData(
    String name,
    String email,
    String phone,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, name);
    await prefs.setString(_kEmail, email);
    await prefs.setString(_kPhone, phone);
  }

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_kName),
      'email': prefs.getString(_kEmail),
      'phone': prefs.getString(_kPhone),
    };
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kPhone);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
