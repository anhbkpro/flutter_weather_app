import 'package:shared_preferences/shared_preferences.dart';

import '../models/city.dart';

/// Persists which cities the user has selected in Settings.
///
/// Uses [SharedPreferencesAsync] (the modern replacement for the legacy
/// [SharedPreferences.getInstance()] API) — reads always hit platform
/// storage, so we don't have to manage a cache or worry about stale data.
///
/// First launch: no key stored yet — we treat that as "all 10 cities selected"
/// so the app is useful out of the box.
class PreferencesService {
  static const String _selectedCitiesKey = 'selected_city_ids_v1';

  final SharedPreferencesAsync _prefs;

  PreferencesService({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  /// Returns the ordered list of selected cities.
  /// The returned list preserves the order defined in [kCityCatalog].
  Future<List<City>> loadSelectedCities() async {
    final stored = await _prefs.getStringList(_selectedCitiesKey);
    if (stored == null) {
      // First launch: all cities selected by default.
      return List<City>.from(kCityCatalog);
    }
    final selected = stored.toSet();
    return kCityCatalog.where((c) => selected.contains(c.id)).toList();
  }

  /// Persists the user's new selection. Order does not matter — we always
  /// re-order against [kCityCatalog] when loading.
  Future<void> saveSelectedCities(Iterable<City> cities) async {
    await _prefs.setStringList(
      _selectedCitiesKey,
      cities.map((c) => c.id).toList(),
    );
  }
}
