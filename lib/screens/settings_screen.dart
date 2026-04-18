import 'package:flutter/material.dart';

import '../models/city.dart';
import '../services/preferences_service.dart';

/// Settings page: the user checks which cities they want to follow.
/// Selections are persisted via [PreferencesService].
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefs = PreferencesService();
  final Set<String> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final cities = await _prefs.loadSelectedCities();
    setState(() {
      _selected
        ..clear()
        ..addAll(cities.map((c) => c.id));
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
