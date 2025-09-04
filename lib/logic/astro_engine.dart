import 'dart:math';

/// A data class to hold the results of an astronomical calculation.
class CelestialData {
  final double sunLongitude;
  final double moonLongitude;
  final double sunAltitude;
  final double sunAzimuth;
  final double moonAltitude;
  final double moonAzimuth;
  final double sunHourAngle;
  final double moonHourAngle;

  CelestialData({
    required this.sunLongitude,
    required this.moonLongitude,
    required this.sunAltitude,
    required this.sunAzimuth,
    required this.moonAltitude,
    required this.moonAzimuth,
    required this.sunHourAngle,
    required this.moonHourAngle,
  });
}

/// A class to perform astronomical calculations for the sun and moon.
class AstroEngine {
  /// Calculates the celestial positions of the sun and moon.
  ///
  /// [dateTime]: The date and time for the calculation.
  /// [latitude]: The observer's latitude.
  /// [longitude]: The observer's longitude.
  CelestialData calculate(DateTime dateTime, double latitude, double longitude) {
    double jd = toJulianDay(dateTime);
    double d = jd - 2451545.0;

    List<double> sunEcl = _getSunCoords(d);
    List<double> moonEcl = _getMoonCoords(d);
    double lSun = sunEcl[0];
    double lMoon = moonEcl[0];

    double obliquity = 23.4397;
    double lst = _getLST(jd, longitude);

    List<double> sunEquatorial = _toEquatorial(lSun, obliquity);
    double sunH = _normalizeAngle(lst - sunEquatorial[0]);
    List<double> sunAltAz = _toAltAz(sunH, sunEquatorial[1], latitude);

    List<double> moonEquatorial = _toEquatorial(lMoon, obliquity);
    double moonH = _normalizeAngle(lst - moonEquatorial[0]);
    List<double> moonAltAz = _toAltAz(moonH, moonEquatorial[1], latitude);

    return CelestialData(
      sunLongitude: lSun,
      moonLongitude: lMoon,
      sunAltitude: sunAltAz[0],
      sunAzimuth: sunAltAz[1],
      moonAltitude: moonAltAz[0],
      moonAzimuth: moonAltAz[1],
      sunHourAngle: sunH,
      moonHourAngle: moonH,
    );
  }

  /// Converts a DateTime object to a Julian Day.
  double toJulianDay(DateTime cal) {
    return cal.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
  }

  /// Normalizes an angle to be within the 0-360 degree range.
  double _normalizeAngle(double angle) {
    double b = angle / 360;
    double a = 360 * (b - b.floor());
    return a < 0 ? a + 360 : a;
  }
  
  /// Helper to convert degrees to radians.
  double _toRadians(double degrees) => degrees * (pi / 180);

  /// Helper to convert radians to degrees.
  double _toDegrees(double radians) => radians * (180 / pi);

  List<double> _getSunCoords(double d) {
    double m = _normalizeAngle(357.5291 + 0.98560028 * d);
    double l = _normalizeAngle(280.4665 +
        0.98564736 * d +
        1.9148 * sin(_toRadians(m)) +
        0.0200 * sin(_toRadians(2 * m)));
    return [l, 0];
  }

  List<double> _getMoonCoords(double d) {
    double l = _normalizeAngle(218.316 + 13.176396 * d);
    return [l, 0];
  }

  List<double> _toEquatorial(double lon, double ob) {
    double lonRad = _toRadians(lon);
    double obRad = _toRadians(ob);
    double x = cos(lonRad);
    double y = sin(lonRad) * cos(obRad);
    double z = sin(lonRad) * sin(obRad);
    double ra = atan2(y, x);
    return [_toDegrees(ra), _toDegrees(asin(z))];
  }

  List<double> _toAltAz(double h, double dec, double lat) {
    double hRad = _toRadians(h);
    double decRad = _toRadians(dec);
    double latRad = _toRadians(lat);
    double sinAlt =
        sin(decRad) * sin(latRad) + cos(decRad) * cos(latRad) * cos(hRad);
    double alt = asin(sinAlt);
    double cosAz =
        (sin(decRad) - sinAlt * sin(latRad)) / (cos(alt) * cos(latRad));
    double az = acos(cosAz);
    return [
      _toDegrees(alt),
      (sin(hRad) > 0.0) ? 360 - _toDegrees(az) : _toDegrees(az)
    ];
  }

  double _getLST(double jd, double longitude) {
    double t = (jd - 2451545.0) / 36525.0;
    double gmst0 = 280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * t * t -
        t * t * t / 38710000.0;
    return _normalizeAngle(gmst0 + longitude);
  }
}