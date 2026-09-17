class WeatherForecastModel {
  final String location;
  final double temperature;
  final String condition;
  final int humidity;
  final double windSpeedKm;
  final int rainProbability;
  final List<DailyForecast> dailyForecasts;
  final List<String> farmingTips;

  WeatherForecastModel({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeedKm,
    required this.rainProbability,
    required this.dailyForecasts,
    required this.farmingTips,
  });
}

class DailyForecast {
  final String dayName;
  final double maxTemp;
  final double minTemp;
  final String condition;
  final int rainChance;

  DailyForecast({
    required this.dayName,
    required this.maxTemp,
    required this.minTemp,
    required this.condition,
    required this.rainChance,
  });
}
