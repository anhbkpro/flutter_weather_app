import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/city.dart';
import '../models/temperature_unit.dart';

/// Persists user-facing settings:
///   * which catalog cities are enabled,
///   * any custom cities the user has added via the geocoding search,
///   * the chosen temperature unit.
///
/// Uses [SharedPreferencesAsync] (the modern replacement for the legacy
/// [SharedPreferences.getInstance()] API) — reads always hit platform
/// storage, so we don't have to manage a cache or worry about stale data.
///
/// First launch: no keys stored yet — we treat that as "all 10 catalog
/// cities selected, no custom cities, Celsius unit" so the app is useful
/// out of the box.
class PreferencesService {
  static const String _selectedCitiesKey = 'selected_city_ids_v1';
  static const String _customCitiesKey = 'custom_cities_v1';
  static const String _temperatureUnitKey = 'temperature_unit_v1';

  final SharedPreferencesAsync _prefs;

  PreferencesService({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  /// Returns the ordered list of catalog cities the user has enabled.
  /// The returned list preserves the order defined in [kCityCatalog].
  Future<List<City>> loadSelectedCities() async {
    final stored = await _prefs.getStringList(_selectedCitiesKey);
    if (stored == null) {
      // First launch: all catalog cities selected by default.
      return List<City>.from(kCityCatalog);
    }
    final selected = stored.toSet();
    return kCityCatalog.where((c) => selected.contains(c.id)).toList();
  }

  /// Persists the user's catalog selection. Order does not matter — we always
  /// re-order against [kCityCatalog] when loading.
  Future<void> saveSelectedCities(Iterable<City> cities) async {
    await _prefs.setStringList(
      _selectedCitiesKey,
      cities.map((c) => c.id).toList(),
    );
  }

  /// Returns the user-added cities (if any), in the order they were added.
  Future<List<City>> loadCustomCities() async {
    final stored = await _prefs.getStringList(_customCitiesKey);
    if (stored == null) return const [];
    final result = <City>[];
    for (final raw in stored) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        result.add(City.fromJson(json));
      } catch (_) {
        // Drop unreadable entries rather than crashing — stored data may
        // come from an older format on upgrade.
      }
    }
    return result;
  }

  /// Persists the user-added cities. Order is preserved.
  Future<void> saveCustomCities(Iterable<City> cities) async {
    await _prefs.setStringList(
      _customCitiesKey,
      cities.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  /// Convenience: full ordered list of cities to display on the home screen
  /// (catalog selections first, in catalog order, then custom cities in
  /// the order they were added).
  Future<List<City>> loadDisplayCities() async {
    final catalog = await loadSelectedCities();
    final custom = await loadCustomCities();
    return [...catalog, ...custom];
  }

  /// Returns the unit the user wants to see temperatures in.
  /// Defaults to Celsius if nothing has been stored yet.
  Future<TemperatureUnit> loadTemperatureUnit() async {
    final stored = await _prefs.getString(_temperatureUnitKey);
    return TemperatureUnit.fromStorageKey(stored);
  }

  /// Persists the user's chosen temperature unit.
  Future<void> saveTemperatureUnit(TemperatureUnit unit) async {
    await _prefs.setString(_temperatureUnitKey, unit.storageKey);
  }
}
