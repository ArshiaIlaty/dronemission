// ignore_for_file: non_constant_identifier_names

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dronemission/elevations_extraction.dart';
import 'package:dronemission/pathing.dart';


void calculateElevations() {
  // Step 1
  // Assuming Contours, user polygon P, and waypoints are already defined.

  // Step 2
  Map<List<double>, double> dem = {}; // Initialize your DEM here.

  // Step 3
  List<double> demLat = [], demLong = [];
  for(List<double> key in dem.keys) {
    demLat.add(key[0]);
    demLong.add(key[1]);
  }

  // Step 4
  List<List<double>> arrLat = List.generate(numberOfSubLists, (_) => []);
  List<List<double>> arrLong = List.generate(numberOfSubLists, (_) => []);

  List<double> elevations = List.filled(waypoints.length, 0.0);

  // Step 5
  List<double> bounds = LATLNG_BOUNDS(polygon);
  double Minlat = bounds[0], Maxlat = bounds[1], Minlon = bounds[2], Maxlong = bounds[3];

  // Step 6 and 7
  List<double> IndexboundsLat = linearSearch(arrLat, Minlat, Maxlat);
  List<double> IndexboundsLong = linearSearch(arrLong, Minlon, Maxlong);

  // Step 8 and 9
  List<double> contourpointsInsidePolygon = [];
  for (int j = 0; j < IndexboundsLat.length; j++) {
    for (int k = 0; k < IndexboundsLong.length; k++) {
      if (dem.containsKey([arrLat[IndexboundsLat[j]], arrLong[IndexboundsLong[k]]])) {
        contourpointsInsidePolygon.add(dem[[arrLat[IndexboundsLat[j]], arrLong[IndexboundsLong[k]]]]!);
      }
    }
  }

  // Step 15
  if (contourpointsInsidePolygon.length != 0) {
    // Step 17
    for (int i = 0; i < waypoints.length; i++) {
      // Step 18
      Map<double, List<double>> insideTheWaypointCircle = {};

      // Step 20
      for (int l = 0; l < contourpointsInsidePolygon.length; l++) {
        // Step 21
        double d = computeDistancebetween(contourpointsInsidePolygon[l], waypoints[i]);
        // Step 22
        if (d < 30) {
          insideTheWaypointCircle[d] = [contourpointsInsidePolygon[l]];
        }
      }

      // Step 26
      if (insideTheWaypointCircle.length != 0) {
        double min = insideTheWaypointCircle.keys.reduce((a, b) => a < b ? a : b);
        elevations[i] = dem[insideTheWaypointCircle[min]![0]]!;
      } else {
        elevations[i] = elevations[i - 1];
      }
    }
  }

  // computeDistancebetween function
  double computeDistancebetween(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // pi / 180
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}

