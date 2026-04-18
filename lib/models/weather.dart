/// Weather data for a single city.
class WeatherData {
  /// Current temperature in Celsius.
  final double currentTemperature;

  /// Open-Meteo WMO weather code for current conditions.
  final int currentWeatherCode;

  /// Current local time at the city (from the API, already in the city's tz).
  final DateTime currentTime;

  /// Whether it is daytime at the city right now. Open-Meteo returns 1/0;
  /// we normalize to bool so the UI can pick a day- or night-themed background.
  final bool isDay;

  /// Daily forecast for today and the next 6 days (7 entries total).
  final List<DailyForecast> daily;

  const WeatherData({
    required this.currentTemperature,
    required this.currentWeatherCode,
    required this.currentTime,
    required this.isDay,
    required this.daily,
  });

  factory WeatherData.fromOpenMeteo(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    final dates = (daily['time'] as List).cast<String>();
    final maxTemps = (daily['temperature_2m_max'] as List).cast<num>();
    final minTemps = (daily['temperature_2m_min'] as List).cast<num>();
    final codes = (daily['weather_code'] as List).cast<num>();

    final forecasts = <DailyForecast>[
      for (var i = 0; i < dates.length; i++)
        DailyForecast(
          date: DateTime.parse(dates[i]),
          maxTemperature: maxTemps[i].toDouble(),
          minTemperature: minTemps[i].toDouble(),
          weatherCode: codes[i].toInt(),
        ),
    ];

    return WeatherData(
      currentTemperature: (current['temperature_2m'] as num).toDouble(),
      currentWeatherCode: (current['weather_code'] as num).toInt(),
      currentTime: DateTime.parse(current['time'] as String),
      isDay: ((current['is_day'] as num?)?.toInt() ?? 1) == 1,
      daily: forecasts,
    );
  }
}

/// A single day in the 7-day forecast.
class DailyForecast {
  final DateTime date;
  final double maxTemperature;
  final double minTemperature;
  final int weatherCode;

  const DailyForecast({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.weatherCode,
  });
}

/// Maps an Open-Meteo WMO weather code to a short human label.
/// See https://open-meteo.com/en/docs for the full table.
String weatherLabelFromCode(int code) {
  if (code == 0) return 'Clear sky';
  if (code == 1) return 'Mainly clear';
  if (code == 2) return 'Partly cloudy';
  if (code == 3) return 'Overcast';
  if (code == 45 || code == 48) return 'Fog';
  if (code >= 51 && code <= 57) return 'Drizzle';
  if (code >= 61 && code <= 67) return 'Rain';
  if (code >= 71 && code <= 77) return 'Snow';
  if (code >= 80 && code <= 82) return 'Rain showers';
  if (code >= 85 && code <= 86) return 'Snow showers';
  if (code == 95) return 'Thunderstorm';
  if (code == 96 || code == 99) return 'Thunderstorm w/ hail';
  return 'Unknown';
}
