import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kissan_connect/core/models/weather_model.dart';

class WeatherService {
  // 1. Convert district/village name to latitude & longitude
  static Future<Map<String, double>?> getCoordinates(
    String locationName,
  ) async {
    try {
      final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(locationName)}&count=1&language=en&format=json',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final first = data['results'][0];
          return {
            'lat': (first['latitude'] as num).toDouble(),
            'lon': (first['longitude'] as num).toDouble(),
          };
        }
      }
    } catch (e) {
      // Fallback below
    }
    // Default fallback: Mathura, Uttar Pradesh coordinates
    return {'lat': 27.4924, 'lon': 77.6737};
  }

  // 2. Fetch live metrics and 7-day agricultural forecast
  static Future<WeatherForecastModel> fetchRealWeather(
    String locationName,
  ) async {
    final coords = await getCoordinates(locationName);
    final lat = coords?['lat'] ?? 27.4924;
    final lon = coords?['lon'] ?? 77.6737;

    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load live weather');
    }

    final data = json.decode(res.body);
    final current = data['current'];
    final daily = data['daily'];

    final double temp = (current['temperature_2m'] as num).toDouble();
    final int humidity = (current['relative_humidity_2m'] as num).toInt();
    final double wind = (current['wind_speed_10m'] as num).toDouble();
    final int weatherCode = (current['weather_code'] as num).toInt();
    final String condition = _interpretWeatherCode(weatherCode);

    final List<dynamic> dates = daily['time'];
    final List<dynamic> maxTemps = daily['temperature_2m_max'];
    final List<dynamic> minTemps = daily['temperature_2m_min'];
    final List<dynamic> codes = daily['weather_code'];
    final List<dynamic> rainChances = daily['precipitation_probability_max'];

    final List<DailyForecast> forecasts = [];
    for (int i = 0; i < dates.length && i < 5; i++) {
      final parsedDate = DateTime.parse(dates[i]);
      final dayLabel = i == 0
          ? 'Today'
          : (i == 1 ? 'Tomorrow' : DateFormat('EEEE').format(parsedDate));
      forecasts.add(
        DailyForecast(
          dayName: dayLabel,
          maxTemp: (maxTemps[i] as num).toDouble(),
          minTemp: (minTemps[i] as num).toDouble(),
          condition: _interpretWeatherCode((codes[i] as num).toInt()),
          rainChance: (rainChances[i] as num?)?.toInt() ?? 0,
        ),
      );
    }

    final int todayRainChance = forecasts.isNotEmpty
        ? forecasts[0].rainChance
        : 0;
    final List<String> advice = _generateAgriAdvisory(
      temp,
      humidity,
      wind,
      todayRainChance,
    );

    return WeatherForecastModel(
      location: locationName,
      temperature: temp,
      condition: condition,
      humidity: humidity,
      windSpeedKm: wind,
      rainProbability: todayRainChance,
      dailyForecasts: forecasts,
      farmingTips: advice,
    );
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

  // Generate dynamic agricultural advice from real parameters
  static List<String> _generateAgriAdvisory(
    double temp,
    int humidity,
    double wind,
    int rainChance,
  ) {
    final List<String> tips = [];

    if (rainChance > 45) {
      tips.add(
        'High chance of rainfall ($rainChance%). Suspend fertilizer application and irrigation to avoid field runoff.',
      );
      tips.add(
        'Ensure drainage ditches in low-lying crop fields are cleared to prevent waterlogging.',
      );
    } else {
      tips.add(
        'Low probability of rain ($rainChance%). Suitable window for field ploughing, tilling, and harvest operations.',
      );
    }

    if (wind > 20.0) {
      tips.add(
        'High wind speeds (${wind.toStringAsFixed(1)} km/h). Delay tractor pesticide spraying to avoid drift.',
      );
    } else {
      tips.add(
        'Favorable wind conditions. Ideal for boom and tractor sprayers.',
      );
    }

    if (temp > 35.0) {
      tips.add(
        'High ambient temperatures. Schedule early-morning or late-evening irrigation to minimize evaporation.',
      );
    } else if (temp < 12.0) {
      tips.add(
        'Cool weather. Monitor young seedlings for frost risk and fungal developments.',
      );
    }

    return tips;
  }
}
