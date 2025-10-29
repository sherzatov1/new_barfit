import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ModeRepository {
  static const String _kSavedModesKey = 'savedModes';
  static const String _kActiveModeKey = 'active_mode_for_threescreen';

  /// Load saved modes from SharedPreferences, returning a deduplicated list (by name).
  static Future<List<Map<String, dynamic>>> loadSavedModes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kSavedModesKey) ?? [];
    final loaded = list.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();
    // Deduplicate by normalized name (trim + lowercase) to avoid duplicates caused by
    // case differences or stray whitespace.
    final List<Map<String, dynamic>> deduped = [];
    final Set<String> seen = {};
    for (var m in loaded) {
      final String rawName = (m['modeName'] ?? m['name'] ?? '').toString();
      final String name = rawName.trim();
      if (name.isEmpty) continue;
      final String normalized = name.toLowerCase();
      if (!seen.contains(normalized)) {
        // Ensure stored mode has consistent modeName/name trimmed
        m['modeName'] = name;
        m['name'] = name;
        deduped.add(m);
        seen.add(normalized);
      }
    }

    // If duplicates were removed or we normalized names, persist the cleaned list back to prefs
    if (deduped.length != loaded.length) {
      await saveSavedModes(deduped);
    }

    return deduped;
  }

  static Future<void> saveSavedModes(List<Map<String, dynamic>> modes) async {
    final prefs = await SharedPreferences.getInstance();
    // Normalize and dedupe before saving to ensure consistent storage.
    final List<Map<String, dynamic>> cleaned = [];
    final Set<String> seen = {};
    for (var m in modes) {
      final String rawName = (m['modeName'] ?? m['name'] ?? '').toString();
      final String name = rawName.trim();
      if (name.isEmpty) continue;
      final String normalized = name.toLowerCase();
      if (!seen.contains(normalized)) {
        m['modeName'] = name;
        m['name'] = name;
        cleaned.add(m);
        seen.add(normalized);
      }
    }
    await prefs.setStringList(_kSavedModesKey, cleaned.map((e) => jsonEncode(e)).toList());
  }

  static Future<void> setActiveMode(Map<String, dynamic> mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveModeKey, jsonEncode(mode));
    // Notify listeners in-app that the active mode changed.
    activeModeNotifier.value = Map<String, dynamic>.from(mode);
  }

  static Future<void> clearActiveMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveModeKey);
    activeModeNotifier.value = null;
  }

  static Future<Map<String, dynamic>?> getActiveMode() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kActiveModeKey);
    if (s == null) return null;
    return Map<String, dynamic>.from(jsonDecode(s));
  }

  // Notifier to allow UI to react to changes in the active mode without
  // requiring a full prefs reload. Listeners should call getActiveMode() if
  // they need the persisted value, but this notifier provides immediate updates.
  static final ValueNotifier<Map<String, dynamic>?> activeModeNotifier = ValueNotifier(null);
}
