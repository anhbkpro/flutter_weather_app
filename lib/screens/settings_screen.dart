import 'package:flutter/material.dart';

import '../models/city.dart';
import '../models/temperature_unit.dart';
import '../services/preferences_service.dart';

/// Settings page: the user checks which cities they want to follow and
/// chooses their preferred temperature unit. Selections are persisted via
/// [PreferencesService].
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
                    'Pick which cities appear in the swipeable home screen.',
                  ),
                ),
                const SizedBox(height: 8),
                for (final city in kCityCatalog)
                  CheckboxListTile(
                    value: _selected.contains(city.id),
                    onChanged: (v) => _toggle(city, v),
                    title: Text(city.name),
                    subtitle: Text(city.country),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
              ],
            ),
    );
  }
}
