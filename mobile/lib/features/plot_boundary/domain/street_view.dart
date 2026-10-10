import 'package:latlong2/latlong.dart';

/// Google Street View deep link for [point] (same URL as the Angular popups).
Uri streetViewUri(LatLng point) => Uri.https('www.google.com', '/maps/@', {
      'api': '1',
      'map_action': 'pano',
      'viewpoint': '${point.latitude},${point.longitude}',
    });
