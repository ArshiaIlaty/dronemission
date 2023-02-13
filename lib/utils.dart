import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vector_math/vector_math.dart';


// Constants
const double EARTH_RADIUS = 6371009;

// Compute the LatLng offset from the input coords by a specified distance and heading
LatLng computeOffset(LatLng coords, double distance, double heading) {
  // Convert the distance from meters to radians
  distance /= EARTH_RADIUS;
  // Convert the heading from degrees to radians
  heading = radians(heading);

  // Compute the spherical coordinates of the input LatLng
  double fromLat = radians(coords.latitude);
  double fromLng = radians(coords.longitude);

  // Compute intermediate values for the final LatLng
  double cosDistance = cos(distance);
  double sinDistance = sin(distance);
  double sinFromLat = sin(fromLat);
  double cosFromLat = cos(fromLat);

  // Compute the final LatLng
  double sinLat = cosDistance * sinFromLat + sinDistance * cosFromLat * cos(heading);
  double dLng = atan2(
      sinDistance * cosFromLat * sin(heading),
      cosDistance = sinFromLat * sinLat
  );
  return LatLng(degrees(asin(sinLat)), degrees(fromLng + dLng));
}

// Get the waypoints along a given Polygon with a specified forward offset
List<LatLng> getWaypointsAlongPolygon(Polygon p, double forwardOffset) {
  // Initialize the list to store the waypoints
  List<LatLng> waypoints = [];
  // Get the list of vertices in the Polygon
  List<LatLng> vertices = p.points;

  // Loop through the vertices to get the waypoints
  for (int i = 0; i < vertices.length - 1; i++) {
    // Add the current vertex as a waypoint
    waypoints.add(vertices.elementAt(i));

    // Compute the distance and bearing between the current vertex and the next one
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

    // Add intermediate waypoints along the line between the current vertex and the next one
    for (int j = 1; j * forwardOffset < distance; j++) {
      waypoints.add(computeOffset(vertices.elementAt(i), j * forwardOffset, bearing));
    }
  }
  // Return the list of waypoints
  return waypoints;
}
