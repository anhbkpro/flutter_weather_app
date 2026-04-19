import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/city.dart';

/// Resolves typed city names → list of [City] candidates using the free
/// Open-Meteo geocoding API. No API key required.
///
/// Docs: https://open-meteo.com/en/docs/geocoding-api
///
/// Each result includes lat/lon and an IANA timezone — exactly what
/// [WeatherService] needs, so candidates can be added to the user's list
/// without any further lookup.
class GeocodingService {
  static const String _baseUrl =
      'https://geocoding-api.open-meteo.com/v1/search';

  final http.Client _client;

  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  /// Searches for [query]. Returns up to [count] candidates ordered by the
  /// API's relevance score. Returns an empty list for blank queries instead
  /// of hitting the network.
  Future<List<City>> search(String query, {int count = 5}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'name': trimmed,
      'count': count.toString(),
      'language': 'en',
      'format': 'json',
    });

    try {
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );
      if (response.statusCode != 200) {
        throw GeocodingException(
          'Geocoding API returned ${response.statusCode}',
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (json['results'] as List?) ?? const [];
      return [
        for (final raw in results.cast<Map<String, dynamic>>())
          _cityFromResult(raw),
      ];
    } on GeocodingException {
      rethrow;
    } catch (e) {
      throw GeocodingException('Search failed: $e');
    }
  }

  City _cityFromResult(Map<String, dynamic> raw) {
    // Open-Meteo sometimes omits `country` for tiny localities; fall back to
    // `country_code` or admin region so the UI never shows a blank subtitle.
    final country = (raw['country'] as String?) ??
        (raw['country_code'] as String?) ??
        (raw['admin1'] as String?) ??
        '';
    return City.custom(
      name: raw['name'] as String,
      country: country,
      latitude: (raw['latitude'] as num).toDouble(),
      longitude: (raw['longitude'] as num).toDouble(),
      // `timezone` is always returned as a valid IANA name for forecast use.
      timezone: raw['timezone'] as String,
    );
  }

  void dispose() => _client.close();
}

class GeocodingException implements Exception {
  final String message;
  GeocodingException(this.message);

  @override
  String toString() => message;
}
