// ignore_for_file: non_constant_identifier_names

import 'dart:core';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dronemission/pathing.dart';


// LATLNG_BOUNDS function
List<double> LATLNG_BOUNDS(List<List<double>> polygon) {
  double minLat = double.infinity, maxLat = -double.infinity;
  double minLng = double.infinity, maxLng = -double.infinity;
  for (int i = 0; i < polygon.length; i++) {
    double lat = polygon[i][0];
    double lng = polygon[i][1];
    if (lat < minLat) minLat = lat;
    if (lat > maxLat) maxLat = lat;
    if (lng < minLng) minLng = lng;
    if (lng > maxLng) maxLng = lng;
  }
  return [minLat, maxLat, minLng, maxLng];
}


// dem class with get and put methods
class Dem {
  Map<String, double> _map = {};

  double? get(double lat, double lng) {
    return _map["$lat,$lng"];
  }

  void put(double lat, double lng, double elevation) {
    _map["$lat,$lng"] = elevation;
  }
}

Map<double, Map<double, double>> dem = {}; // initialize empty dem map

void demLatitude(List<Map<String, dynamic>> data) {
  Set<double> latitudes = {};
  for (var i = 0; i < data.length; i++) {
    latitudes.add(data[i]['lat']);
  }
  List<double> sortedLatitudes = latitudes.toList()..sort();
  for (var i = 0; i < sortedLatitudes.length; i++) {
    dem[sortedLatitudes[i]] = {};
  }
}

void demLongitude(List<Map<String, dynamic>> data) {
  Set<double> longitudes = {};
  for (var i = 0; i < data.length; i++) {
    longitudes.add(data[i]['lng']);
  }
  List<double> sortedLongitudes = longitudes.toList()..sort();
  for (var i = 0; i < sortedLongitudes.length; i++) {
    for (var j = 0; j < dem.keys.length; j++) {
      dem[dem.keys.elementAt(j)]![sortedLongitudes[i]];
    }
  }
}


List<double> demLat = []; // Initialize empty list for latitude values
List<double> demLong = []; // Initialize empty list for longitude values

// Loop through each entry in `dem` map and add latitude and longitude values to their respective lists
dem.forEach((key, value) {
  demLat.add(key.latitude);
  demLong.add(key.longitude);
});

// Remove any duplicate values from `demLat` and `demLong`
demLat = demLat.toSet().toList();
demLong = demLong.toSet().toList();

// Sort `demLat` and `demLong` in ascending order
demLat.sort();
demLong.sort();


// Algorithm 1: Elevations_Extraction
List<double> elevationsExtraction(
    Map dem, Polygon Polygon, List<LatLng> waypoints) {
  List<double> elevations = List<double>.filled(waypoints.length, 0.0);
  List<double> arrLat = demLatitudes(dem);
  List<double> arrLong = demLongitudes(dem);
  List<double> Lat = [];
  List<double> Long = [];

  // Step 5: LATLNG_BOUNDS
  LatLngBounds bounds = Polygon.bounds;    
  // LatLng_Bounds(Polygon.vertices);
  List<double> indexboundsLat = linearSearch(
      arrLat, bounds.southwest.latitude, bounds.northeast.latitude);
  List<double> indexboundsLong = linearSearch(
      arrLong, bounds.southwest.longitude, bounds.northeast.longitude);

  for (double i = 0.0; i < indexboundsLat.length; i++) {
    Lat.add(arrLat[indexboundsLat[i]]);
  }

  for (double i = 0; i < indexboundsLong.length; i++) {
    Long.add(arrLong[indexboundsLong[i]]);
  }

  for (int i = 0; i < waypoints.length; i++) {
    double minlat = waypoints[i].latitude - 0.00005;
    double maxlat = waypoints[i].latitude + 0.00005;
    double minlong = waypoints[i].longitude - 0.00005;
    double maxlong = waypoints[i].longitude + 0.00005;

    if (minlat > Lat[0] && maxlat < Lat[Lat.length - 1]) {
      List<double> latbounds = linearSearch(Lat, minlat, maxlat);
      if (minlong > Long[0] && maxlong < Long[Long.length - 1]) {
        List<double> longbounds = linearSearch(Long, minlong, maxlong);
        List<double> temp = [];
        for (int j = 0; j < latbounds.length; j++) {
          for (int k = 0; k < longbounds.length; k++) {
            temp.add(dem[Lat[j]][Long[k]]);
          }
        }
        double sum = 0;
        for (int k = 0; k < temp.length; k++) {
          sum += temp[k];
        }
        if (temp.length != 0) {
          elevations[i] = sum / temp.length;
        }
      }
    }
  }
  return elevations;
}

// Algorithm 2: LINEARSEARCH
List<double> linearSearch(List<double> arrLat, double Minlat, double Maxlat) {
  int n = arrLat.length;
  int i = 0;
  int j = 0;
  List<double> Idxbounds = [];

  while (arrLat[i] < Minlat) {
    i = i + 1;
  }
  Idxbounds.add(i - 1);
  j = i;
  while (arrLat[j] < Maxlat) {
    j = j + 1;
  }
  Idxbounds.add(j + 1);
  return Idxbounds;
}
