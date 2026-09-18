import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kissan_connect/core/models/weather_model.dart';

class WeatherService {
  // Safe helper to parse num to double
  static double _toDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? fallback;
  }

  // Safe helper to parse num to int
  static int _toInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? fallback;
  }

  // Geocoding: Extracts a clean city/district name to avoid API misses
  static Future<Map<String, double>> getCoordinates(String rawLocation) async {
    // Default fallback: Mathura, Uttar Pradesh
    const defaultCoords = {'lat': 27.4924, 'lon': 77.6737};

    // Extract first significant token (e.g. "Farah, Mathura" -> "Farah" or "Mathura")
    String query = rawLocation.split(',').first.trim();
    if (query.isEmpty) query = 'Mathura';

    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': query,
        'count': '1',
        'language': 'en',
        'format': 'json',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final first = data['results'][0];
          return {
            'lat': _toDouble(first['latitude'], defaultCoords['lat']!),
            'lon': _toDouble(first['longitude'], defaultCoords['lon']!),
          };
        }
      }
    } catch (e) {
      debugPrint('Geocoding error ($query): $e');
    }

    return defaultCoords;
  }

  // Live forecast retrieval
  static Future<WeatherForecastModel> fetchRealWeather(
    String locationName,
  ) async {
    try {
      final coords = await getCoordinates(locationName);
      final lat = coords['lat']!;
      final lon = coords['lon']!;

      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        'timezone': 'auto',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final current = data['current'] as Map<String, dynamic>?;
      final daily = data['daily'] as Map<String, dynamic>?;

      if (current == null || daily == null) {
        throw Exception('Incomplete weather payload');
      }

      final double temp = _toDouble(current['temperature_2m']);
      final int humidity = _toInt(current['relative_humidity_2m']);
      final double wind = _toDouble(current['wind_speed_10m']);
      final int weatherCode = _toInt(current['weather_code']);
      final String condition = _interpretWeatherCode(weatherCode);

      final List dates = daily['time'] ?? [];
      final List maxTemps = daily['temperature_2m_max'] ?? [];
      final List minTemps = daily['temperature_2m_min'] ?? [];
      final List codes = daily['weather_code'] ?? [];
      final List rainChances = daily['precipitation_probability_max'] ?? [];

      final List<DailyForecast> forecasts = [];
      final int count = dates.length;

      for (int i = 0; i < count && i < 5; i++) {
        DateTime? parsedDate;
        try {
          parsedDate = DateTime.parse(dates[i].toString());
        } catch (_) {
          parsedDate = DateTime.now().add(Duration(days: i));
        }

        final String dayLabel = i == 0
            ? 'Today'
            : (i == 1 ? 'Tomorrow' : DateFormat('EEEE').format(parsedDate));

        forecasts.add(
          DailyForecast(
            dayName: dayLabel,
            maxTemp: _toDouble(i < maxTemps.length ? maxTemps[i] : temp),
            minTemp: _toDouble(i < minTemps.length ? minTemps[i] : temp - 5),
            condition: _interpretWeatherCode(
              _toInt(i < codes.length ? codes[i] : 0),
            ),
            rainChance: _toInt(i < rainChances.length ? rainChances[i] : 0),
          ),
        );
      }

      final int todayRainChance = forecasts.isNotEmpty
          ? forecasts[0].rainChance
          : 0;
      final List<String> tips = _generateAgriAdvisory(
        temp,
        humidity,
        wind,
        todayRainChance,
      );

      return WeatherForecastModel(
        location: locationName.isNotEmpty ? locationName : 'Mathura',
        temperature: temp,
        condition: condition,
        humidity: humidity,
        windSpeedKm: wind,
        rainProbability: todayRainChance,
        dailyForecasts: forecasts,
        farmingTips: tips,
      );
    } catch (e) {
      debugPrint('Weather fetch failure: $e');
      rethrow;
    }
  }

  static String _interpretWeatherCode(int code) {
    if (code == 0) return 'Clear Sky';
    if (code >= 1 && code <= 3) return 'Partly Cloudy';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rain';
    if (code >= 80 && code <= 82) return 'Rain Showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Overcast';
  }

  static List<String> _generateAgriAdvisory(
    double temp,
    int humidity,
    double wind,
    int rainChance,
  ) {
    final List<String> tips = [];

    if (rainChance > 40) {
      tips.add(
        'High rain likelihood ($rainChance%). Pause irrigation and fertilizer spreading.',
      );
      tips.add(
        'Ensure field drainage channels are cleared to prevent root rot.',
      );
    } else {
      tips.add(
        'Dry weather ahead ($rainChance% rain chance). Good for harvesting and seed-bed preparation.',
      );
    }

    if (wind > 18.0) {
      tips.add(
        'Windy conditions (${wind.toStringAsFixed(1)} km/h). Delay tractor sprayer operations.',
      );
    } else {
      tips.add('Optimal wind velocity. Safe for sprayers and weed control.');
    }

    if (temp > 34.0) {
      tips.add(
        'High heat (${temp.round()}°C). Irrigate early morning or post-sunset.',
      );
    }

    return tips;
  }
}
