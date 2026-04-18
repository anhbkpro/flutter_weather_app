import 'package:flutter/material.dart';

/// Maps an Open-Meteo WMO weather code to a Material icon.
/// Kept intentionally simple — we don't ship a full icon set.
IconData iconForWeatherCode(int code) {
  if (code == 0) return Icons.wb_sunny;
  if (code == 1) return Icons.wb_sunny_outlined;
  if (code == 2) return Icons.cloud_queue;
  if (code == 3) return Icons.cloud;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code >= 51 && code <= 57) return Icons.grain;
  if (code >= 61 && code <= 67) return Icons.umbrella;
  if (code >= 71 && code <= 77) return Icons.ac_unit;
  if (code >= 80 && code <= 82) return Icons.beach_access;
  if (code >= 85 && code <= 86) return Icons.ac_unit;
  if (code == 95 || code == 96 || code == 99) return Icons.flash_on;
  return Icons.help_outline;
}
