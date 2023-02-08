import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vector_math/vector_math.dart';


const double EARTH_RADIUS = 6371009;

LatLng computeOffset(LatLng coords, double distance, double heading) {
  distance /= EARTH_RADIUS;
  heading = radians(heading);
  double fromLat = radians(coords.latitude);
  double fromLng = radians(coords.longitude);
  double cosDistance = cos(distance);
  double sinDistance = sin(distance);
  double sinFromLat = sin(fromLat);
  double cosFromLat = cos(fromLat);
  double sinLat = cosDistance * sinFromLat + sinDistance * cosFromLat * cos(heading);
  double dLng = atan2(
      sinDistance * cosFromLat * sin(heading),
      cosDistance = sinFromLat * sinLat
  );
  return LatLng(degrees(asin(sinLat)), degrees(fromLng + dLng));
}

List<LatLng> getWaypointsAlongPolygon(Polygon p, double forwardOffset) {
  List<LatLng> waypoints = [];
  List<LatLng> vertices = p.points;

  for (int i = 0; i < vertices.length - 1; i++) {
    waypoints.add(vertices.elementAt(i));

    double distance = Geolocator.distanceBetween(
      vertices.elementAt(i).latitude,
      vertices.elementAt(i).longitude,
      vertices.elementAt(i + 1).latitude,
      vertices.elementAt(i + 1).longitude,
    );

    double bearing = Geolocator.bearingBetween(
      vertices.elementAt(i).latitude,
      vertices.elementAt(i).longitude,
      vertices.elementAt(i + 1).latitude,
      vertices.elementAt(i + 1).longitude,
    );

    for (int j = 1; j * forwardOffset < distance; j++) {
      waypoints.add(computeOffset(vertices.elementAt(i), j * forwardOffset, bearing));
    }
  }
  return waypoints;
}