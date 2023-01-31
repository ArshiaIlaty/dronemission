// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// class PolygonService {
//   final List<LatLng> _coordinates = [];
//   final Set<Polygon> _polygons = {};
//
//   void createPolygon(List<LatLng> coordinates) {
//     _coordinates.addAll(coordinates);
//     _polygons.add(Polygon(
//       polygonId: PolygonId(_coordinates.length.toString()),
//       points: _coordinates,
//       fillColor: Colors.green.withOpacity(0.5),
//       strokeWidth: 5,
//       strokeColor: Colors.green,
//     ));
//   }
//
//   void editPolygonEdge(int index, LatLng newCoordinate) {
//     _coordinates[index] = newCoordinate;
//     _polygons.clear();
//     _polygons.add(Polygon(
//       polygonId: PolygonId(_coordinates.length.toString()),
//       points: _coordinates,
//       fillColor: Colors.green.withOpacity(0.5),
//       strokeWidth: 5,
//       strokeColor: Colors.green,
//     ));
//   }
//
//   void deletePolygonEdge(int index) {
//     _coordinates.removeAt(index);
//     _polygons.clear();
//     _polygons.add(Polygon(
//         polygonId: PolygonId(_coordinates.length.toString()),
//     points: _coordinates,
