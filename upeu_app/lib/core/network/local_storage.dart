import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keyToken = 'auth_token';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserId = 'user_id';

  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  // Token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  String? getToken() {
    return _prefs.getString(_keyToken);
  }

  Future<void> removeToken() async {
    await _prefs.remove(_keyToken);
  }

  // Role
  Future<void> saveUserRole(String role) async {
    await _prefs.setString(_keyUserRole, role);
  }

  String? getUserRole() {
    return _prefs.getString(_keyUserRole);
  }

  // User ID
  Future<void> saveUserId(int id) async {
    await _prefs.setInt(_keyUserId, id);
  }

  int? getUserId() {
    return _prefs.getInt(_keyUserId);
  }

  // Limpiar todo
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // Verificar si hay sesión activa
  bool hasActiveSession() {
    return getToken() != null;
  }
}