import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

// Define a class to hold a single centerpoint
class Centerpoint {
  late LatLng point;
  bool insidePolygon = false;
  Centerpoint(this.point, this.insidePolygon);
}

// Returns a list of points from top left to right, back and forth, that covers the polygon.
List<LatLng> findPath(Polygon polygon, int resolution) {

  // Generate a bounding box around the polygon.
  final points = polygon.points;
  final pointsUtil = points.map((point) => mp.LatLng(point.latitude, point.longitude)).toList();
  var min_lat = double.maxFinite;
  var min_lon = double.maxFinite;
  var max_lat = double.negativeInfinity;
  var max_lon = double.negativeInfinity;
  for (final point in points) {
    if (point.latitude >= max_lat) {
      max_lat = point.latitude;
    }
    if (point.latitude <= min_lat) {
      min_lat = point.latitude;
    }
    if (point.longitude >= max_lon) {
      max_lon = point.longitude;
    }
    if (point.longitude <= min_lon) {
      min_lon = point.longitude;
    }
  }

  // Rasterize the box while 'coloring' every centerpoint inside the polygon.
  //calculate the distance between each row and column of centerpoints
  // Rasterize the bounding box while 'coloring' every centerpoint inside the polygon
  final double lat_stride = (max_lat - min_lat)/resolution;
  final double lon_stride = (max_lon - min_lon)/resolution;

  // Create a 2D list of centerpoints
  final List<List<Centerpoint>> centerpoints = List.generate(resolution, (i) => List.generate(resolution, (j) => Centerpoint(LatLng(0,0), false)));

  // Start rasterizing from the top left corner of the bounding box
  var direction = 'right';
  for (var y = resolution - 1; y >= 0; y--) {
    if (direction == 'right') {
      // Rasterize from left to right
      for (var x = 0; x < resolution; x++) {
        final point = LatLng(min_lat + y * lat_stride, min_lon + x * lon_stride);
        // Check if the centerpoint is inside the polygon and 'color' it accordingly
        centerpoints[y][x] = Centerpoint(point, mp.PolygonUtil.containsLocation(mp.LatLng(point.latitude, point.longitude), pointsUtil, false));
      }
      // Change direction
      direction = 'left';
    } else {
      // Rasterize from right to left
      for (var x = resolution - 1; x >= 0; x--) {
        final point = LatLng(min_lat + y * lat_stride, min_lon + x * lon_stride);
        // Check if the centerpoint is inside the polygon and 'color' it accordingly
        centerpoints[y][x] = Centerpoint(point, mp.PolygonUtil.containsLocation(mp.LatLng(point.latitude, point.longitude), pointsUtil, false));
      }
      // Change direction
      direction = 'right';
    }
  }

  //TODO: Expand rasterized shape by 1.
  // Create a list of points from top left to right, back and forth, that cover the polygon
  final List<LatLng> path = [];

  direction = 'right';
  for (var y = resolution - 1; y >= 0; y--) {
    if (direction == 'right') {
      // Traverse from left to right
      for (var x = 0; x < resolution; x++) {
        if (centerpoints[y][x].insidePolygon) {
          path.add(centerpoints[y][x].point);
        }
      }
      direction = 'left';
    } else {
      for (var x = resolution - 1; x >= 0; x--) {
        if (centerpoints[y][x].insidePolygon) {
          path.add(centerpoints[y][x].point);
        }
      }
      direction = 'right';
    }
  }


  return path;
}
