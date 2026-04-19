/// Temperature unit the user wants to see in the UI.
///
/// The Open-Meteo API always returns values in Celsius — conversion happens
/// only at the display layer via [convert] / [format].
enum TemperatureUnit {
  celsius('C', '°C'),
  fahrenheit('F', '°F');

  /// Short identifier persisted to SharedPreferences. Do not change — it is
  /// part of the on-disk format.
  final String storageKey;

  /// Unit suffix used when formatting, e.g. "23°C" or "73°F".
  final String symbol;

  const TemperatureUnit(this.storageKey, this.symbol);

  /// Convert a Celsius value to this unit.
  double convert(double celsius) {
    switch (this) {
      case TemperatureUnit.celsius:
        return celsius;
      case TemperatureUnit.fahrenheit:
        return celsius * 9 / 5 + 32;
    }
  }

  /// Render a Celsius value as a rounded string with a degree sign, e.g.
  /// `23°C`. Pass [includeSymbol] = false to get just `23°`.
  String format(double celsius, {bool includeSymbol = true}) {
    final value = convert(celsius).round();
    return includeSymbol ? '$value$symbol' : '$value°';
  }

  /// Parse a [storageKey] back to an enum value. Falls back to Celsius for
  /// unknown / missing values.
  static TemperatureUnit fromStorageKey(String? key) {
    for (final unit in TemperatureUnit.values) {
      if (unit.storageKey == key) return unit;
    }
    return TemperatureUnit.celsius;
  }
}
