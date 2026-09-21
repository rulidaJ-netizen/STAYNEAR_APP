import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

enum LocationProblem { denied, deniedForever, disabled, unavailable }

class PropertyLocationException implements Exception {
  const PropertyLocationException(this.problem, this.message);
  final LocationProblem problem;
  final String message;
}

/// Shared platform boundary, also injectable for navigation/location tests.
class PropertyLocationService {
  static double distanceBetween(LatLng boarder, LatLng property) =>
      Geolocator.distanceBetween(
        boarder.latitude,
        boarder.longitude,
        property.latitude,
        property.longitude,
      );

  static String formatDistance(double meters) => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(1)} km';

  static Uri? savedMapUri(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null || !['https', 'http'].contains(uri.scheme)) return null;
    final host = uri.host.toLowerCase();
    final googleHost =
        host == 'google.com' ||
        host.endsWith('.google.com') ||
        host == 'google.com.ph' ||
        host.endsWith('.google.com.ph');
    final mapsPath = uri.path == '/maps' || uri.path.startsWith('/maps/');
    return (googleHost && (mapsPath || host.startsWith('maps.'))) ||
            host == 'maps.app.goo.gl' ||
            host == 'maps.google' ||
            (host == 'goo.gl' && uri.path.startsWith('/maps/'))
        ? uri
        : null;
  }

  static LatLng? coordinates(double? latitude, double? longitude) {
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        (latitude == 0 && longitude == 0)) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  /// Only use a pin/query coordinate, never the map camera's @lat,lng viewport.
  static LatLng? coordinatesFromMapLink(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        !(uri.host == 'google.com' ||
            uri.host.endsWith('.google.com') ||
            uri.host == 'maps.google.com.ph' ||
            uri.host == 'www.google.com.ph')) {
      return null;
    }
    for (final key in ['query', 'q', 'destination']) {
      final value = uri.queryParameters[key];
      if (value == null) continue;
      final match = RegExp(r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$')
          .firstMatch(value);
      if (match != null) {
        return coordinates(
          double.tryParse(match[1]!),
          double.tryParse(match[2]!),
        );
      }
    }
    final pin = RegExp(r'!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)')
        .firstMatch(link);
    return pin == null
        ? null
        : coordinates(double.tryParse(pin[1]!), double.tryParse(pin[2]!));
  }

  Future<LatLng> currentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const PropertyLocationException(
          LocationProblem.disabled,
          'Location services are off. Turn them on to get directions.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const PropertyLocationException(
          LocationProblem.deniedForever,
          'Location access is blocked. Enable it in app settings to get directions.',
        );
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw const PropertyLocationException(
          LocationProblem.denied,
          'Location permission was denied. You can still view the property on the map.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } on PropertyLocationException {
      rethrow;
    } catch (_) {
      throw const PropertyLocationException(
        LocationProblem.unavailable,
        'Could not get your location. Please try again.',
      );
    }
  }

  static String destination(LatLng? point, String address) =>
      point == null ? address.trim() : '${point.latitude},${point.longitude}';

  static Uri mapUri(LatLng? point, String address) => Uri.https(
    'www.google.com',
    '/maps/search/',
    {'api': '1', 'query': destination(point, address)},
  );

  static Uri directionsUri(LatLng point) =>
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${point.latitude},${point.longitude}',
        'travelmode': 'driving',
      });

  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
  Future<bool> openSettings(LocationProblem problem) =>
      problem == LocationProblem.disabled
      ? Geolocator.openLocationSettings()
      : Geolocator.openAppSettings();
}
