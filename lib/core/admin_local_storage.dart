import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminLocalStorage {
  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString('admin_token', token);
  }

  static Future<String> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString('admin_token') ?? '';
  }

  static Future<void> saveAdmin(Map<String, dynamic> admin) async {
    final prefs = await _getPrefs();
    await prefs.setString('admin_data', json.encode(admin));
  }

  static Future<Map<String, dynamic>> getAdmin() async {
    final prefs = await _getPrefs();
    final data = prefs.getString('admin_data');
    if (data != null && data.isNotEmpty) {
      try {
        return json.decode(data) as Map<String, dynamic>;
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  static Future<void> saveRole(String role) async {
    final prefs = await _getPrefs();
    await prefs.setString('admin_role', role);
  }

  static Future<String> getRole() async {
    final prefs = await _getPrefs();
    return prefs.getString('admin_role') ?? 'SUPPORT';
  }

  static Future<void> clear() async {
    final prefs = await _getPrefs();
    await prefs.remove('admin_token');
    await prefs.remove('admin_data');
    await prefs.remove('admin_role');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token.isNotEmpty;
  }
}