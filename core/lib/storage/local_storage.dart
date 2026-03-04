import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

/// Interface for type adapters to handle complex types in SharedPreferences.
abstract class PrefAdapter<T> {
  Future<void> write(SharedPreferences prefs, String key, T value);
  T? read(SharedPreferences prefs, String key);
}

class _StringAdapter extends PrefAdapter<String> {
  @override
  Future<void> write(SharedPreferences prefs, String key, String value) => prefs.setString(key, value);
  @override
  String? read(SharedPreferences prefs, String key) => prefs.getString(key);
}

class _IntAdapter extends PrefAdapter<int> {
  @override
  Future<void> write(SharedPreferences prefs, String key, int value) => prefs.setInt(key, value);
  @override
  int? read(SharedPreferences prefs, String key) => prefs.getInt(key);
}

class _BoolAdapter extends PrefAdapter<bool> {
  @override
  Future<void> write(SharedPreferences prefs, String key, bool value) => prefs.setBool(key, value);
  @override
  bool? read(SharedPreferences prefs, String key) => prefs.getBool(key);
}

class _DoubleAdapter extends PrefAdapter<double> {
  @override
  Future<void> write(SharedPreferences prefs, String key, double value) => prefs.setDouble(key, value);
  @override
  double? read(SharedPreferences prefs, String key) => prefs.getDouble(key);
}

class _StringListAdapter extends PrefAdapter<List<String>> {
  @override
  Future<void> write(SharedPreferences prefs, String key, List<String> value) => prefs.setStringList(key, value);
  @override
  List<String>? read(SharedPreferences prefs, String key) => prefs.getStringList(key);
}

class _JsonMapAdapter extends PrefAdapter<Map<String, dynamic>> {
  @override
  Future<void> write(SharedPreferences prefs, String key, Map<String, dynamic> value) => prefs.setString(key, jsonEncode(value));
  @override
  Map<String, dynamic>? read(SharedPreferences prefs, String key) {
    final s = prefs.getString(key);
    return s == null ? null : jsonDecode(s) as Map<String, dynamic>;
  }
}

/// A helper class for managing local data persistence using SharedPreferences.
class SharedPrefHelper {
  static const _selectedTheme = "selectedTheme";
  static const _selectedLanguage = "selectedLanguage";
  static const _selectedFont = "selectedFont";
  static const _introducerKey = "introducerKey";
  static const _tenantIdKey = "tenantIdKey";

  late SharedPreferences preferences;

  final Map<Type, PrefAdapter> _adapters = {
    String: _StringAdapter(),
    int: _IntAdapter(),
    bool: _BoolAdapter(),
    double: _DoubleAdapter(),
    List<String>: _StringListAdapter(),
    Map<String, dynamic>: _JsonMapAdapter(),
  };

  SharedPrefHelper();

  Future<void> init() async {
    preferences = await SharedPreferences.getInstance();
  }

  bool containsKey(String key) => preferences.containsKey(key);

  Future<bool> remove(String key) => preferences.remove(key);

  Future<bool> clear() => preferences.clear();

  T? get<T>(String key) {
    final adapter = _adapters[T];
    if (adapter != null) {
      return (adapter as PrefAdapter<T>).read(preferences, key);
    }
    if (T == dynamic || T == Map) {
      final s = preferences.getString(key);
      return s == null ? null : jsonDecode(s) as T?;
    }
    return null;
  }

  Future<bool> set<T>(String key, T value) async {
    final adapter = _adapters[T] ?? _adapters[value.runtimeType];
    if (adapter != null) {
      await (adapter as PrefAdapter<T>).write(preferences, key, value);
      return true;
    }
    if (value is Map || value is List) {
      return await preferences.setString(key, jsonEncode(value));
    }
    return false;
  }

  int getThemeIndex() => get<int>(_selectedTheme) ?? 0;
  Future<void> saveThemeIndex(int value) => set<int>(_selectedTheme, value);

  int getLanguageIndex() => get<int>(_selectedLanguage) ?? 0;
  Future<void> saveLanguageIndex(int value) => set<int>(_selectedLanguage, value);

  int getFontSize() => get<int>(_selectedFont) ?? 0;
  Future<void> saveFontSize(int value) => set<int>(_selectedFont, value);

  IntroducerModel? getIntroducer() {
    final jsonMap = get<Map<String, dynamic>>(_introducerKey);
    return jsonMap == null ? null : IntroducerModel.fromJson(jsonMap);
  }

  Future<void> saveIntroducer(IntroducerModel value) => set<Map<String, dynamic>>(_introducerKey, value.toJson());

  String? getTenantId() => get<String>(_tenantIdKey);
  Future<void> saveTenantId(String value) => set<String>(_tenantIdKey, value);
}

/// Secure storage helper using flutter_secure_storage.
class SecureAuthStorage {
  Future<void> saveToken(String key, String token) async {
    logAuth.info('SecureAuthStorage: Saving token for $key (Mocked)');
  }

  Future<String?> readToken(String key) async {
    logAuth.info('SecureAuthStorage: Reading token for $key (Mocked)');
    return null;
  }

  Future<void> clearAll() async {
    logAuth.info('SecureAuthStorage: Clearing all tokens (Mocked)');
  }
}
