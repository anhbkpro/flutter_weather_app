import 'dart:async';

import 'package:flutter/material.dart';

import '../models/city.dart';
import '../models/temperature_unit.dart';
import '../services/geocoding_service.dart';
import '../services/preferences_service.dart';

/// Settings page. Lets the user:
///   * pick a temperature unit (°C / °F),
///   * toggle which built-in catalog cities to follow,
///   * search for and add their own custom cities (geocoded via Open-Meteo),
///   * remove any selected city by swiping it off (Dismissible).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefs = PreferencesService();
  final GeocodingService _geo = GeocodingService();

  final Set<String> _selected = {};
  final List<City> _customCities = [];
  TemperatureUnit _unit = TemperatureUnit.celsius;
  bool _loading = true;

  // Search state.
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<City> _searchResults = const [];
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _geo.dispose();
    super.dispose();
  }

  Future<void> _loadCurrent() async {
    final cities = await _prefs.loadSelectedCities();
    final custom = await _prefs.loadCustomCities();
    final unit = await _prefs.loadTemperatureUnit();
    setState(() {
      _selected
        ..clear()
        ..addAll(cities.map((c) => c.id));
      _customCities
        ..clear()
        ..addAll(custom);
      _unit = unit;
      _loading = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Catalog (kCityCatalog) selection
  // ---------------------------------------------------------------------------

  Future<void> _toggleCatalog(City city, bool? value) async {
    setState(() {
      if (value ?? false) {
        _selected.add(city.id);
      } else {
        _selected.remove(city.id);
      }
    });
    await _prefs.saveSelectedCities(
      kCityCatalog.where((c) => _selected.contains(c.id)),
    );
  }

  Future<void> _removeCatalogViaSwipe(City city) async {
    setState(() => _selected.remove(city.id));
    await _prefs.saveSelectedCities(
      kCityCatalog.where((c) => _selected.contains(c.id)),
    );
    _showUndoSnackBar(
      message: 'Removed ${city.name}',
      onUndo: () async {
        setState(() => _selected.add(city.id));
        await _prefs.saveSelectedCities(
          kCityCatalog.where((c) => _selected.contains(c.id)),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Custom (user-added) cities
  // ---------------------------------------------------------------------------

  Future<void> _addCustomCity(City city) async {
    // Reject duplicates (same id) — covers both already-added customs and
    // attempts to re-add a city that's also in the catalog.
    final inCatalog = kCityCatalog.any(
      (c) =>
          c.name.toLowerCase() == city.name.toLowerCase() &&
          c.country.toLowerCase() == city.country.toLowerCase(),
    );
    final inCustom = _customCities.any((c) => c.id == city.id);
    if (inCatalog || inCustom) {
      _showInfoSnackBar('${city.name} is already in your list');
      return;
    }

    setState(() {
      _customCities.add(city);
      _searchController.clear();
      _searchResults = const [];
      _searchError = null;
    });
    await _prefs.saveCustomCities(_customCities);
    _showInfoSnackBar('Added ${city.name}');
  }

  Future<void> _removeCustomViaSwipe(City city) async {
    final removedAt = _customCities.indexWhere((c) => c.id == city.id);
    setState(() {
      _customCities.removeWhere((c) => c.id == city.id);
    });
    await _prefs.saveCustomCities(_customCities);
    _showUndoSnackBar(
      message: 'Removed ${city.name}',
      onUndo: () async {
        setState(() {
          // Restore at original position when possible.
          final i = removedAt.clamp(0, _customCities.length);
          _customCities.insert(i, city);
        });
        await _prefs.saveCustomCities(_customCities);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  void _onSearchChanged(String value) {
    // Debounce the network call, but rebuild immediately so the clear (×)
    // suffix icon appears as soon as the user starts typing.
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = const [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    setState(() {}); // refresh suffixIcon visibility
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String value) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await _geo.search(value);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _searching = false;
        _searchError = e.toString();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Misc
  // ---------------------------------------------------------------------------

  Future<void> _setUnit(TemperatureUnit? unit) async {
    if (unit == null || unit == _unit) return;
    setState(() => _unit = unit);
    await _prefs.saveTemperatureUnit(unit);
  }

  void _showUndoSnackBar({
    required String message,
    required Future<void> Function() onUndo,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Undo', onPressed: () => onUndo()),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _sectionHeader('Temperature unit'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SegmentedButton<TemperatureUnit>(
                    segments: const [
                      ButtonSegment(
                        value: TemperatureUnit.celsius,
                        label: Text('Celsius (°C)'),
                        icon: Icon(Icons.thermostat),
                      ),
                      ButtonSegment(
                        value: TemperatureUnit.fahrenheit,
                        label: Text('Fahrenheit (°F)'),
                        icon: Icon(Icons.thermostat_auto),
                      ),
                    ],
                    selected: {_unit},
                    onSelectionChanged: (s) => _setUnit(s.first),
                  ),
                ),
                const Divider(height: 32),

                _sectionHeader('Add a city'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Da Nang, Berlin, Seoul',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _runSearch,
                  ),
                ),
                _buildSearchResults(),
                const Divider(height: 32),

                _sectionHeader('Cities you follow'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tap a checkbox to toggle, or swipe a city to remove it.',
                  ),
                ),
                const SizedBox(height: 8),
                for (final city in kCityCatalog) _catalogTile(city),
                if (_customCities.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Added by you',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  for (final city in _customCities) _customTile(city),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      );

  Widget _buildSearchResults() {
    if (_searching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_searchError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          'Search failed: $_searchError',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_searchResults.isEmpty) {
      if (_searchController.text.trim().isEmpty) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          'No matches. Try a different spelling.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return Column(
      children: [
        for (final result in _searchResults)
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(result.name),
            subtitle: Text(result.country),
            trailing: IconButton(
              tooltip: 'Add ${result.name}',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addCustomCity(result),
            ),
            onTap: () => _addCustomCity(result),
          ),
      ],
    );
  }

  /// Catalog city row. Selected → wrapped in Dismissible; otherwise plain.
  Widget _catalogTile(City city) {
    final tile = CheckboxListTile(
      value: _selected.contains(city.id),
      onChanged: (v) => _toggleCatalog(city, v),
      title: Text(city.name),
      subtitle: Text(city.country),
      controlAffinity: ListTileControlAffinity.leading,
    );

    if (!_selected.contains(city.id)) return tile;

    return Dismissible(
      key: ValueKey('city_dismiss_${city.id}'),
      direction: DismissDirection.endToStart,
      background: _swipeBackground(),
      onDismissed: (_) => _removeCatalogViaSwipe(city),
      child: tile,
    );
  }

  /// Custom city row. Always Dismissible — swipe deletes the city entirely.
  Widget _customTile(City city) {
    return Dismissible(
      key: ValueKey('city_dismiss_${city.id}'),
      direction: DismissDirection.endToStart,
      background: _swipeBackground(),
      onDismissed: (_) => _removeCustomViaSwipe(city),
      child: ListTile(
        leading: const Icon(Icons.location_city),
        title: Text(city.name),
        subtitle: Text(city.country),
        trailing: IconButton(
          tooltip: 'Remove ${city.name}',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _removeCustomViaSwipe(city),
        ),
      ),
    );
  }

  Widget _swipeBackground() => Container(
        color: Colors.red.shade600,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.white),
          ],
        ),
      );
}
