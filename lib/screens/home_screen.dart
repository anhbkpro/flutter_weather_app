import 'package:flutter/material.dart';

import '../models/city.dart';
import '../services/preferences_service.dart';
import 'settings_screen.dart';
import 'weather_page.dart';

/// The main screen: a swipeable PageView of selected cities.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PreferencesService _prefs = PreferencesService();
  late PageController _controller;
  List<City> _cities = [];
  int _currentPage = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await _prefs.loadSelectedCities();
    setState(() {
      _cities = cities;
      _loading = false;
      // Clamp in case the previously selected page no longer exists.
      if (_currentPage >= _cities.length) {
        _currentPage = _cities.isEmpty ? 0 : _cities.length - 1;
      }
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
    // Selections may have changed — reload.
    await _loadCities();
    if (_controller.hasClients && _cities.isNotEmpty) {
      _controller.jumpToPage(_currentPage);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Transparent Scaffold + transparent AppBar let each WeatherPage's
    // gradient flow behind the app bar.
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          _cities.isEmpty || _loading
              ? 'Weather'
              : _cities[_currentPage].name,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _cities.length > 1
          ? _PageIndicator(
              count: _cities.length,
              current: _currentPage,
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cities.isEmpty) {
      return _EmptyState(onOpenSettings: _openSettings);
    }
    return PageView.builder(
      controller: _controller,
      itemCount: _cities.length,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemBuilder: (context, index) {
        return WeatherPage(
          key: ValueKey(_cities[index].id),
          city: _cities[index],
        );
      },
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _PageIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    // Dots are rendered on top of the per-page gradient, so use white +
    // translucent white for good contrast against any backdrop.
    final active = Colors.white;
    final inactive = Colors.white.withValues(alpha: 0.35);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: i == current ? 20 : 8,
                decoration: BoxDecoration(
                  color: i == current ? active : inactive,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _EmptyState({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    // Scaffold backgroundColor is black, so keep content bright.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_city, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'No cities selected.\nOpen Settings to pick a few.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
