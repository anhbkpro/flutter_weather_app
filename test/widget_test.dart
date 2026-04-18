// Smoke test for the weather app.
//
// The full app fetches data from Open-Meteo and requires
// SharedPreferences, so here we just verify it builds without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';

void main() {
  testWidgets('WeatherApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
