// Shared per-service session drafts (generic): every shell that swaps
// services (the planner shell, the composer shell) snapshots the outgoing
// session per (zone + service) and restores the incoming one
// ("restore draft, lazy re-price").

import 'package:core/core.dart';

/// Per-service session drafts keyed by (zone key + service key) — switching
/// services snapshots the outgoing session and restores the incoming one's
/// draft. Persisted under one shared-prefs JSON blob so drafts survive
/// process restarts; an in-memory mirror avoids re-parsing per quick
/// switches. Drafts are best-effort transport (JSON-serializable maps).
class SessionDraftsStore {
  /// The drafts blob key — the owner's OWN identifier. Stored data must
  /// not move specs: the key stays exactly as the owner wrote it.
  final String prefsKey;

  /// Idle-shell restore source: the last service the user picked per zone.
  /// Its own blob — never collides with service drafts.
  final String lastKey;

  /// The tag used in the best-effort warnings (the owner's own wording).
  final String logTag;

  final SharedPrefHelper prefs;

  /// Loaded-once mirror; writes go to both.
  final Map<String, Map<String, Map<String, dynamic>>> _cache = {};
  bool _loaded = false;

  /// Last-service mirror (zoneKey → serviceKey).
  final Map<String, String> _last = {};
  bool _lastLoaded = false;

  SessionDraftsStore(
    this.prefs, {
    required this.prefsKey,
    required this.lastKey,
    required this.logTag,
  });

  Map<String, Map<String, dynamic>> _bucket(String zoneKey) =>
      _cache.putIfAbsent(zoneKey, () => {});

  /// Sync-on-first-use hydration; malformed blobs degrade to empty.
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = prefs.get<Map<String, dynamic>>(prefsKey);
      if (raw != null) {
        raw.forEach((zoneKey, services) {
          if (services is Map<String, dynamic>) {
            _cache[zoneKey] = {
              for (final e in services.entries)
                if (e.value is Map<String, dynamic>)
                  e.key: Map<String, dynamic>.from(e.value as Map),
            };
          }
        });
      }
    } catch (e) {
      Object().logNet.warning('$logTag: hydrate failed: $e');
    }
  }

  /// The incoming owner's draft (null = fresh session).
  Future<Map<String, dynamic>?> take(String zoneKey, String serviceKey) async {
    await _ensureLoaded();
    return _bucket(zoneKey)[serviceKey];
  }

  /// Snapshot the outgoing session (persisted best-effort).
  Future<void> save(
    String zoneKey,
    String serviceKey,
    Map<String, dynamic> draft,
  ) async {
    if (draft.isEmpty) return;
    await _ensureLoaded();
    _bucket(zoneKey)[serviceKey] = draft;
    await _persist();
  }

  /// A completed order invalidates that service's draft (fresh session next
  /// time).
  Future<void> clear(String zoneKey, String serviceKey) async {
    await _ensureLoaded();
    if (_bucket(zoneKey).remove(serviceKey) != null) {
      await _persist();
    }
  }

  /// Remember the service the user picked in [zoneKey] (idle-shell restore
  /// source). Best-effort — failures log, never throw.
  Future<void> setLastService(String zoneKey, String serviceKey) async {
    try {
      _last[zoneKey] = serviceKey;
      _lastLoaded = true;
      await prefs.set<Map<String, dynamic>>(lastKey, {
        for (final e in _last.entries) e.key: e.value,
      });
    } catch (e) {
      Object().logNet.warning('$logTag: set last failed: $e');
    }
  }

  /// The idle shell's restore candidate (null = never picked in this zone).
  Future<String?> takeLastService(String zoneKey) async {
    try {
      if (!_lastLoaded) {
        _lastLoaded = true;
        final raw = prefs.get<Map<String, dynamic>>(lastKey);
        if (raw != null) {
          _last
            ..clear()
            ..addAll(raw.map((k, v) => MapEntry(k, v as String)));
        }
      }
      return _last[zoneKey];
    } catch (e) {
      Object().logNet.warning('$logTag: take last failed: $e');
      return null;
    }
  }

  Future<void> _persist() async {
    await prefs.set<Map<String, dynamic>>(prefsKey, {
      for (final e in _cache.entries) e.key: e.value,
    });
  }
}
