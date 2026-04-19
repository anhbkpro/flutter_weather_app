import 'dart:async';

import 'package:flutter/material.dart';

import '../models/city.dart';
import '../models/temperature_unit.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../widgets/weather_background.dart';
import '../widgets/weather_icon.dart';

/// Shows current weather + 7-day forecast for a single [city].
///
/// The page receives the chosen [unit] from the parent so that switching
/// between Celsius and Fahrenheit in Settings re-renders every page instantly
/// without re-fetching data.
class WeatherPage extends StatefulWidget {
  final City city;
  final TemperatureUnit unit;

  const WeatherPage({
    super.key,
    required this.city,
    required this.unit,
  });

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with AutomaticKeepAliveClientMixin {
  final WeatherService _service = WeatherService();
  Future<WeatherData>? _future;

  /// Duration offset between the city's local time and the device's UTC clock,
  /// captured once at load so we can tick the displayed clock without
  /// re-fetching from the API.
  Duration? _localOffset;
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _service.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _future = _service.fetchWeather(widget.city).then((data) {
        _localOffset = data.currentTime.difference(DateTime.now().toUtc());
        return data;
      });
    });
  }

  DateTime _cityLocalNow() {
    if (_localOffset == null) return _now;
    return DateTime.now().toUtc().add(_localOffset!);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<WeatherData>(
      future: _future,
      builder: (context, snapshot) {
        // Pick a neutral dark background while loading / on error so the
        // page doesn't flash white.
        final bg = snapshot.hasData
            ? WeatherBackground.forCode(
                snapshot.data!.currentWeatherCode,
                isDay: snapshot.data!.isDay,
              )
            : WeatherBackground.forCode(3, isDay: true); // overcast day

        Widget content;
        if (snapshot.connectionState != ConnectionState.done) {
          content = Center(
            child: CircularProgressIndicator(color: bg.onColor),
          );
        } else if (snapshot.hasError) {
          content = _ErrorView(
            message: snapshot.error.toString(),
            onRetry: _load,
            onColor: bg.onColor,
          );
        } else {
          content = _WeatherBody(
            city: widget.city,
            data: snapshot.data!,
            localNow: _cityLocalNow(),
            bg: bg,
            unit: widget.unit,
          );
        }

        return Container(
          decoration: BoxDecoration(gradient: bg.gradient),
          child: RefreshIndicator(
            onRefresh: () async => _load(),
            // Make the refresh spinner readable on dark backgrounds.
            color: Colors.black87,
            backgroundColor: Colors.white,
            child: content,
          ),
        );
      },
    );
  }
}

class _WeatherBody extends StatelessWidget {
  final City city;
  final WeatherData data;
  final DateTime localNow;
  final WeatherBackground bg;
  final TemperatureUnit unit;

  const _WeatherBody({
    required this.city,
    required this.data,
    required this.localNow,
    required this.bg,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaTop = MediaQuery.of(context).padding.top + kToolbarHeight;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, mediaTop + 8, 20, 32),
      children: [
        Text(
          city.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: bg.onColor,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          city.country,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: bg.secondaryOnColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _formatLocalTime(localNow),
          style: theme.textTheme.titleMedium?.copyWith(color: bg.onColor),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        Icon(
          iconForWeatherCode(data.currentWeatherCode),
          size: 96,
          color: bg.onColor,
        ),
        const SizedBox(height: 8),
        Text(
          unit.format(data.currentTemperature),
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: bg.onColor,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          weatherLabelFromCode(data.currentWeatherCode),
          style: theme.textTheme.titleMedium?.copyWith(color: bg.onColor),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),
        Divider(color: bg.secondaryOnColor.withValues(alpha: 0.4)),
        const SizedBox(height: 8),
        Text(
          '7-day forecast',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: bg.onColor,
          ),
        ),
        const SizedBox(height: 8),

        for (final day in data.daily) _DailyRow(day: day, bg: bg, unit: unit),
      ],
    );
  }

  String _formatLocalTime(DateTime dt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final wd = weekdays[dt.weekday - 1];
    final mo = months[dt.month - 1];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$wd, $mo ${dt.day} · $hh:$mm';
  }
}

class _DailyRow extends StatelessWidget {
  final DailyForecast day;
  final WeatherBackground bg;
  final TemperatureUnit unit;

  const _DailyRow({
    required this.day,
    required this.bg,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _dayLabel(day.date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(color: bg.onColor),
            ),
          ),
          Icon(iconForWeatherCode(day.weatherCode), color: bg.onColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              weatherLabelFromCode(day.weatherCode),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: bg.secondaryOnColor,
              ),
            ),
          ),
          Text(
            '${unit.format(day.minTemperature, includeSymbol: false)} / '
            '${unit.format(day.maxTemperature, includeSymbol: false)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: bg.onColor,
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime date) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final diff = normalizedDate.difference(normalizedToday).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[date.weekday - 1];
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color onColor;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: onColor),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: onColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
