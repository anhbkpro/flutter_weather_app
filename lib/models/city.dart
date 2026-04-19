/// A city that can be shown in the weather app.
///
/// [id] is a stable identifier used to persist the user's selection.
/// [timezone] is an IANA timezone name (e.g. "Asia/Ho_Chi_Minh") understood
/// by Open-Meteo so that returned timestamps match local time.
///
/// Cities come from two sources:
///   * [kCityCatalog] — the built-in fixed catalog (ids are slugs like
///     "hanoi"). These are always available and toggled on/off via Settings.
///   * User-added custom cities — created with [City.custom] from geocoding
///     results, persisted as JSON via [toJson] / [fromJson].
class City {
  final String id;
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final String timezone;

  const City({
    required this.id,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  /// Builds a custom (user-added) city. The id encodes lat/lon so two
  /// distinct points never collide even if they happen to share a name.
  factory City.custom({
    required String name,
    required String country,
    required double latitude,
    required double longitude,
    required String timezone,
  }) {
    final lat = latitude.toStringAsFixed(4);
    final lon = longitude.toStringAsFixed(4);
    return City(
      id: 'custom_${lat}_$lon',
      name: name,
      country: country,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
    );
  }

  /// True when this city was added by the user (not from [kCityCatalog]).
  bool get isCustom => id.startsWith('custom_');

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
      };

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as String,
        name: json['name'] as String,
        country: json['country'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timezone: json['timezone'] as String,
      );
}

/// The fixed catalog of 10 cities the app supports.
///
/// Order is meaningful: it's the default order in the PageView until the
/// user customizes their selection in Settings.
const List<City> kCityCatalog = [
  City(
    id: 'hanoi',
    name: 'Hanoi',
    country: 'Vietnam',
    latitude: 21.0285,
    longitude: 105.8542,
    timezone: 'Asia/Ho_Chi_Minh',
  ),
  City(
    id: 'hcmc',
    name: 'Ho Chi Minh City',
    country: 'Vietnam',
    latitude: 10.8231,
    longitude: 106.6297,
    timezone: 'Asia/Ho_Chi_Minh',
  ),
  City(
    id: 'tokyo',
    name: 'Tokyo',
    country: 'Japan',
    latitude: 35.6762,
    longitude: 139.6503,
    timezone: 'Asia/Tokyo',
  ),
  City(
    id: 'new_york',
    name: 'New York',
    country: 'USA',
    latitude: 40.7128,
    longitude: -74.0060,
    timezone: 'America/New_York',
  ),
  City(
    id: 'london',
    name: 'London',
    country: 'United Kingdom',
    latitude: 51.5074,
    longitude: -0.1278,
    timezone: 'Europe/London',
  ),
  City(
    id: 'paris',
    name: 'Paris',
    country: 'France',
    latitude: 48.8566,
    longitude: 2.3522,
    timezone: 'Europe/Paris',
  ),
  City(
    id: 'sydney',
    name: 'Sydney',
    country: 'Australia',
    latitude: -33.8688,
    longitude: 151.2093,
    timezone: 'Australia/Sydney',
  ),
  City(
    id: 'dubai',
    name: 'Dubai',
    country: 'UAE',
    latitude: 25.2048,
    longitude: 55.2708,
    timezone: 'Asia/Dubai',
  ),
  City(
    id: 'singapore',
    name: 'Singapore',
    country: 'Singapore',
    latitude: 1.3521,
    longitude: 103.8198,
    timezone: 'Asia/Singapore',
  ),
  City(
    id: 'san_francisco',
    name: 'San Francisco',
    country: 'USA',
    latitude: 37.7749,
    longitude: -122.4194,
    timezone: 'America/Los_Angeles',
  ),
];
