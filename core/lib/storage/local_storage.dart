import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

/// A helper class for managing local data persistence using SharedPreferences.
///
/// Note: [init] must be called once at app startup before any get/set operations.
class SharedPrefHelper {
  // --- Constant Keys ---
  static const _selectedTheme = "selectedTheme";
  static const _selectedLanguage = "selectedLanguage";
  static const _selectedFont = "selectedFont";
  static const _introducerKey = "introducerKey";
  static const _tenantIdKey = "tenantIdKey";

  late SharedPreferences preferences;

  SharedPrefHelper();

  /// Initializes the SharedPreferences instance.
  /// This must be called at the application startup (e.g., in `main`).
  Future<void> init() async {
    preferences = await SharedPreferences.getInstance();
  }

  //
  //
  // ------------------------- Generic Persistence Helpers -------------------------
  //
  //

  bool containsKey(String key) {
    return preferences.containsKey(key);
  }

  Future<bool> remove(String key) async {
    return await preferences.remove(key);
  }

  Future<bool> clear() async {
    return await preferences.clear();
  }

  /// Retrieves a value of a specific type `T`.
  ///
  /// Supports primitive types (`String`, `int`, `double`, `bool`, `List<String>`) directly.
  /// For complex types like `Map` or `List`, it assumes the value was stored as a JSON string and attempts to decode it.
  T? get<T>(String key) {
    // Check for standard SharedPreferences types first.
    // We use `T == Type` because T is a Type object at this point.
    if (T == String) {
      return preferences.getString(key) as T?;
    }
    if (T == int) {
      return preferences.getInt(key) as T?;
    }
    if (T == double) {
      return preferences.getDouble(key) as T?;
    }
    if (T == bool) {
      return preferences.getBool(key) as T?;
    }
    if (T == List<String>) {
      return preferences.getStringList(key) as T?;
    }

    // If T is not a primitive type, assume it's a complex object stored as a JSON string.
    final jsonString = preferences.getString(key);
    if (jsonString != null) {
      try {
        final decodedValue = jsonDecode(jsonString);
        if (!kReleaseMode) {
          logUI.debug('☺ SharedPrefHelper ☺ get decoded $key: $decodedValue (Type: $T)');
        }
        return decodedValue as T?;
      } catch (e) {
        logUI.error('Failed to decode JSON for key "$key": $e');
        return null;
      }
    }

    // Return null if the key doesn't exist or the type is unsupported and not a JSON string.
    return null;
  }

  /// Persists a value to storage.
  ///
  /// Handles primitive types directly. For complex types like `Map` or `List`, it automatically encodes the value to a JSON string before saving.
  Future<bool> set<T>(String key, T value) async {
    if (!kReleaseMode) {
      logUI.debug('☺ SharedPrefHelper ☺ persist new $key: $value (Type: ${value.runtimeType})');
    }

    // Use `is` to check the runtime type of the `value` instance.
    // The order is important: check for the specific List<String> before the general List.
    if (value is String) {
      return await preferences.setString(key, value);
    }
    if (value is int) {
      return await preferences.setInt(key, value);
    }
    if (value is double) {
      return await preferences.setDouble(key, value);
    }
    if (value is bool) {
      return await preferences.setBool(key, value);
    }
    if (value is List<String>) {
      return await preferences.setStringList(key, value);
    }
    // For any other List or a Map, encode it as a JSON string.
    if (value is List || value is Map) {
      try {
        final jsonString = jsonEncode(value);
        return await preferences.setString(key, jsonString);
      } catch (e) {
        logUI.error('Failed to encode value for key "$key" to JSON: $e');
        return false;
      }
    }

    logUI.warning('Unsupported type ${value.runtimeType} for key "$key". Value not set.');
    return false;
  }

  //
  //
  // ------------------------- Application Specific Getters -------------------------
  //
  //

  /// Retrieves the index of the selected theme (defaulting to 0).
  int getThemeIndex() {
    return get<int>(_selectedTheme) ?? 0;
  }

  /// Saves the index of the selected theme.
  Future<void> saveThemeIndex(int value) async {
    await set<int>(_selectedTheme, value);
  }

  /// Retrieves the index of the selected language (defaulting to 0).
  int getLanguageIndex() {
    return get<int>(_selectedLanguage) ?? 0;
  }

  /// Saves the index of the selected language.
  Future<void> saveLanguageIndex(int value) async {
    await set<int>(_selectedLanguage, value);
  }

  /// Retrieves the index of the selected font size (defaulting to 0).
  int getFontSize() {
    return get<int>(_selectedFont) ?? 0;
  }

  /// Saves the index of the selected font size.
  Future<void> saveFontSize(int value) async {
    await set<int>(_selectedFont, value);
  }

  /// Retrieves the state of the app introducer/onboarding status.
  IntroducerModel? getIntroducer() {
    final jsonMap = get<Map<String, dynamic>>(_introducerKey);
    return jsonMap == null ? null : IntroducerModel.fromJson(jsonMap);
  }

  /// Saves the current state of the app introducer/onboarding status.
  Future<void> saveIntroducer(IntroducerModel value) async {
    await set<Map<String, dynamic>>(_introducerKey, value.toJson());
  }

  /// Retrieves the ID of the current tenant for multi-tenant applications.
  String? getTenantId() {
    return get<String>(_tenantIdKey);
  }

  /// Saves the ID of the current tenant.
  Future<void> saveTenantId(String value) async {
    await set<String>(_tenantIdKey, value);
  }
}
