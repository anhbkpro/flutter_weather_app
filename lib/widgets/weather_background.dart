import 'package:flutter/material.dart';

/// A background theme for the weather screen, derived from the current
/// WMO weather code and whether it's day or night at the city.
///
/// We pick gradients dark enough that white text stays readable across
/// all conditions (including "clear day"), then expose an explicit
/// [onColor] / [secondaryOnColor] so callers don't have to guess.
class WeatherBackground {
  final LinearGradient gradient;
  final Color onColor;
  final Color secondaryOnColor;

  const WeatherBackground({
    required this.gradient,
    required this.onColor,
    required this.secondaryOnColor,
  });

  static WeatherBackground forCode(int code, {required bool isDay}) {
    // WMO code groups — see https://open-meteo.com/en/docs
    final group = _groupForCode(code);
    return _palette(group, isDay);
  }

  static _WeatherGroup _groupForCode(int code) {
    if (code == 0 || code == 1) return _WeatherGroup.clear;
    if (code == 2) return _WeatherGroup.partlyCloudy;
    if (code == 3) return _WeatherGroup.overcast;
    if (code == 45 || code == 48) return _WeatherGroup.fog;
    if ((code >= 51 && code <= 57) ||
        (code >= 61 && code <= 67) ||
        (code >= 80 && code <= 82)) {
      return _WeatherGroup.rain;
    }
    if ((code >= 71 && code <= 77) || (code == 85 || code == 86)) {
      return _WeatherGroup.snow;
    }
    if (code == 95 || code == 96 || code == 99) {
      return _WeatherGroup.thunderstorm;
    }
    return _WeatherGroup.overcast;
  }

  static WeatherBackground _palette(_WeatherGroup group, bool isDay) {
    // White text + 80%-white secondary works for every palette below.
    const white = Colors.white;
    final white80 = Colors.white.withValues(alpha: 0.8);

    LinearGradient g;
    switch (group) {
      case _WeatherGroup.clear:
        g = isDay
            // Deep sky blue → bright azure.
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF60A5FA)],
              )
            // Midnight indigo → near black.
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1026), Color(0xFF1E1B4B), Color(0xFF312E81)],
              );
        break;
      case _WeatherGroup.partlyCloudy:
        g = isDay
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF334155), Color(0xFF475569), Color(0xFF64748B)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
              );
        break;
      case _WeatherGroup.overcast:
        g = isDay
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF475569), Color(0xFF64748B), Color(0xFF94A3B8)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1F2937), Color(0xFF374151), Color(0xFF4B5563)],
              );
        break;
      case _WeatherGroup.fog:
        g = isDay
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFB0B6BF)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1F2937), Color(0xFF374151), Color(0xFF6B7280)],
              );
        break;
      case _WeatherGroup.rain:
        g = isDay
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1220), Color(0xFF1E293B), Color(0xFF312E81)],
              );
        break;
      case _WeatherGroup.snow:
        g = isDay
            // Kept dark-ish so white text still reads — pale snow would
            // otherwise require switching to dark text.
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA), Color(0xFF93C5FD)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              );
        break;
      case _WeatherGroup.thunderstorm:
        g = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
        );
        break;
    }

    return WeatherBackground(
      gradient: g,
      onColor: white,
      secondaryOnColor: white80,
    );
  }
}

enum _WeatherGroup {
  clear,
  partlyCloudy,
  overcast,
  fog,
  rain,
  snow,
  thunderstorm,
}
