import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/city.dart';
import '../models/weather.dart';

/// Fetches weather data from the free Open-Meteo forecast API.
/// No API key is required.
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches current weather + 7-day forecast for [city].
  /// Throws a [WeatherException] on network or parsing failure.
  Future<WeatherData> fetchWeather(City city) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'latitude': city.latitude.toString(),
      'longitude': city.longitude.toString(),
      'current': 'temperature_2m,weather_code,is_day',
      'daily': 'temperature_2m_max,temperature_2m_min,weather_code',
      'timezone': city.timezone,
      'forecast_days': '7',
      'temperature_unit': 'celsius',
    });

    try {
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 15),
          );
      if (response.statusCode != 200) {
        throw WeatherException(
          'Weather API returned ${response.statusCode}',
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return WeatherData.fromOpenMeteo(json);
    } on WeatherException {
      rethrow;
    } catch (e) {
      throw WeatherException('Failed to load weather: $e');
    }
  }

  void dispose() => _client.close();
}

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => message;
}
