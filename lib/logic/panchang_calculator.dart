import 'dart:math';
import 'astro_engine.dart'; // Import our newly created file

class HomeData {
  final String tithi;
  final double sunAltitude;
  final double sunAzimuth;
  final double moonAltitude;
  final double moonAzimuth;
  final double sunLongitude;
  final double moonLongitude;
  final double moonPhasePercent;
  final double sunHourAngle;
  final double moonHourAngle;

  HomeData({
    required this.tithi,
    required this.sunAltitude,
    required this.sunAzimuth,
    required this.moonAltitude,
    required this.moonAzimuth,
    required this.sunLongitude,
    required this.moonLongitude,
    required this.moonPhasePercent,
    required this.sunHourAngle,
    required this.moonHourAngle,
  });
}

class PanchangCalculator {
  static const List<String> _tithiNames = [
    "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami", "Shashthi",
    "Saptami", "Ashtami", "Navami", "Dashami", "Ekadashi", "Dwadashi",
    "Trayodashi", "Chaturdashi"
  ];

  static HomeData getHomeData(double latitude, double longitude, double timeOffsetHours) {
    // In Dart, we use UTC and then add the duration.
    final now = DateTime.now().toUtc().add(Duration(hours: timeOffsetHours.toInt()));
    final engine = AstroEngine();

    final celestialData = engine.calculate(now, latitude, longitude);

    var diff = celestialData.moonLongitude - celestialData.sunLongitude;
    if (diff < 0) diff += 360;
    final tithiIndex = (diff / 12).floor();
    
    String paksha;
    String tithiName;

    if (tithiIndex < 15) {
      paksha = "Shukla Paksha";
      tithiName = (tithiIndex == 14) ? "Purnima" : _tithiNames[tithiIndex];
    } else {
      paksha = "Krishna Paksha";
      final krishnaIndex = tithiIndex - 15;
      tithiName = (krishnaIndex == 14) ? "Amavasya" : _tithiNames[krishnaIndex];
    }
    
    final fullTithiName = "$tithiName, $paksha";

    final elongationRad = (diff * (pi / 180));
    final moonPhase = (1 - cos(elongationRad)) / 2;

    return HomeData(
      tithi: fullTithiName,
      sunAltitude: celestialData.sunAltitude,
      sunAzimuth: celestialData.sunAzimuth,
      moonAltitude: celestialData.moonAltitude,
      moonAzimuth: celestialData.moonAzimuth,
      sunLongitude: celestialData.sunLongitude,
      moonLongitude: celestialData.moonLongitude,
      moonPhasePercent: moonPhase,
      sunHourAngle: celestialData.sunHourAngle,
      moonHourAngle: celestialData.moonHourAngle,
    );
  }
}