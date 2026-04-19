import 'package:flutter/material.dart';

import '../models/city.dart';
import '../models/temperature_unit.dart';
import '../services/preferences_service.dart';

/// Settings page: the user checks which cities they want to follow and
/// chooses their preferred temperature unit. Selections are persisted via
/// [PreferencesService].
///
/// A selected city can be removed either by unticking its checkbox or by
/// swiping it off (end-to-start) via a [Dismissible] — the swipe shows a
/// SnackBar with an Undo action in case the gesture was accidental.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefs = PreferencesService();
  final Set<String> _selected = {};
  TemperatureUnit _unit = TemperatureUnit.celsius;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final cities = await _prefs.loadSelectedCities();
    final unit = await _prefs.loadTemperatureUnit();
    setState(() {
      _selected
        ..clear()
        ..addAll(cities.map((c) => c.id));
      _unit = unit;
      _loading = false;
    });
  }

  Future<void> _toggle(City city, bool? value) async {
    setState(() {
      if (value ?? false) {
        _selected.add(city.id);
      } else {
        _selected.remove(city.id);
      }
    });
    await _persist();
  }

  /// Removes [city] from the selection (called by Dismissible) and shows
  /// an Undo SnackBar so the user can recover from an accidental swipe.
  Future<void> _removeViaSwipe(City city) async {
    setState(() => _selected.remove(city.id));
    await _persist();

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // Clear any lingering snackbar so rapid swipes don't stack.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed ${city.name}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            setState(() => _selected.add(city.id));
            await _persist();
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _persist() async {
    await _prefs.saveSelectedCities(
      kCityCatalog.where((c) => _selected.contains(c.id)),
    );
  }

  Future<void> _setUnit(TemperatureUnit? unit) async {
    if (unit == null || unit == _unit) return;
    setState(() => _unit = unit);
    await _prefs.saveTemperatureUnit(unit);
  }

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
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Temperature unit',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Cities you follow',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tap a checkbox to toggle, or swipe a selected city to '
                    'remove it.',
                  ),
                ),
                const SizedBox(height: 8),
                for (final city in kCityCatalog) _cityTile(city),
              ],
            ),
    );
  }

  /// Builds a row for [city]. Selected cities are wrapped in a [Dismissible]
  /// so they can be swiped away; unselected cities render as a plain checkbox
  /// tile (there's nothing to "remove" if they aren't selected).
  Widget _cityTile(City city) {
    final tile = CheckboxListTile(
      value: _selected.contains(city.id),
      onChanged: (v) => _toggle(city, v),
      title: Text(city.name),
      subtitle: Text(city.country),
      controlAffinity: ListTileControlAffinity.leading,
    );

    if (!_selected.contains(city.id)) return tile;

    return Dismissible(
      // Key must be unique & stable per-city so Flutter can match the dismiss
      // animation to the right element.
      key: ValueKey('city_dismiss_${city.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
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
      ),
      onDismissed: (_) => _removeViaSwipe(city),
      child: tile,
    );
  }
}
