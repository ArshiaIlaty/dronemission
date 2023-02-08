import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' show Geolocator, Placemark;
import 'package:flutter_geocoder/geocoder.dart';
import 'package:custom_marker/marker_icon.dart';
import 'package:dronemission/utils.dart';

void main() => runApp(MyApp());

class Polar {
  final double r;
  final double theta;
  Polar(this.r, this.theta);
}


// class WaypointsAlongPolygon {
//   Future<List<LatLng>> waypointsAlongPolygon(Polygon p, double forwardoffset) async {
//     List<LatLng> waypoints = [];
//     List<LatLng> vertices = [];
//     vertices = p.points;
//
//     for (int i = 0; i < vertices.length - 1; i++) {
//       waypoints.add(vertices[i]);
//       double length = await Geolocator.distanceBetween(vertices[i].latitude, vertices[i].longitude, vertices[i + 1].latitude, vertices[i + 1].longitude);
//       double bearing = await Geolocator.bearingBetween(vertices[i].latitude, vertices[i].longitude, vertices[i + 1].latitude, vertices[i + 1].longitude);
//       // double length = computeDistanceBetween(vertices[i], vertices[i + 1]);
//       // double heading = bearingBetween(vertices[i], vertices[i + 1]);
//       int j = 1;
//
//       while (j * (forwardoffset) < length) {
//         waypoints.add(LatLng.computeOffset(vertices[i], j * forwardoffset, heading));
//         j++;
//       }
//     }
//
//     return waypoints;
//   }
// }



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late GoogleMapController mapController;
  Location location = Location();
  LocationData? currentLocation;
  late String _searchString;
  late Position _currentPosition;
  Set<Marker> _markers = {};
  late Marker _currentLocation;
  int _selectedEdge = -1;
  Set<Polygon> _polygons = {};
  Set<Marker> _waypointMarkers = {};
  final Geolocator geolocator = Geolocator();
  final TextEditingController _searchController = TextEditingController();
  List<Polyline> _polylines = [];
  static final random = Random();


  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _currentLocation = const Marker(
      markerId: MarkerId("Current Location"),
      position:
        LatLng(0, 0),
      infoWindow: InfoWindow(title: "Current Location"),
      // icon: ,
      visible: true,
    );
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        this.currentLocation = currentLocation;
        _currentLocation = _currentLocation.copyWith(
              positionParam: LatLng(currentLocation.latitude!, currentLocation.longitude!)
        );
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target:
                  LatLng(currentLocation.latitude!, currentLocation.longitude!),
              zoom: 15.0,
            ),
          ),
        );
      });
    });
  }

  void _searchLocation() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      final results = await Geocoder.local.findAddressesFromQuery(query);
      if (results.isNotEmpty) {
        final first = results.first;
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                  first.coordinates.latitude!!, first.coordinates.longitude!!),
              zoom: 15.0,
            ),
          ),
        );
      }
    }
  }

  getUserLocation() async {
    var location = Location();
    var permission = await location.requestPermission();
    var userLocation = await location.getLocation();
    setState(() {
      _currentPosition = userLocation as Position;
    });
  }

  void _onMapLongPress(LatLng latLng) {
    setState(() {
      // Check if a marker with the same markerId already exists
      final id = (_markers.length + 1).toString();
      final marker = Marker(
        markerId: MarkerId(id),
        position: latLng,
        icon: BitmapDescriptor.defaultMarker,
        draggable: true,
        onDragEnd: (LatLng newPosition) {
          _markers = Set.from(_markers.map((m) => m.markerId.value == id ? m.copyWith(positionParam: newPosition) : m));
          _updatePolygon();
        },
        infoWindow: InfoWindow(
          title: "Marker ${id}",
          snippet: "Tap to delete",
          onTap: () => _onDeletePress(latLng, id),
        ),
      );
      _markers.add(marker);
      _updatePolygon();
    });
  }

  void _onDeletePress(LatLng latLng, String markerId) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == markerId);
    });
    _updatePolygon();
  }

  void _updatePolygon() {
    _polygons.clear();
    if (_markers.length >= 3) {
      final test = Set.from(_markers.map((m) => m.position));
      final origin = test.reduce((value, element) => LatLng(
          (value.latitude + element.latitude) / 2,
          (value.longitude + element.longitude) / 2));
      final polarCoordinates =
      test.map((c) => _toPolar(c, origin)).toList();
      polarCoordinates.sort((a, b) =>
          a.theta == b.theta ? a.r.compareTo(b.r) : a.theta.compareTo(b.theta));
      final orderedCoordinates =
          polarCoordinates.map((p) => _fromPolar(p, origin)).toList();
      setState(() {
        _polygons.clear();
        _polygons.add(Polygon(
          polygonId: PolygonId(test.length.toString()),
          points: orderedCoordinates,
          fillColor: Colors.green.withOpacity(0.5),
          strokeWidth: 3,
          strokeColor: Colors.green,
        ));

        const double overshoot = 10.0;
        final waypoints = getWaypointsAlongPolygon(
            Polygon(
                polygonId: PolygonId(random.nextInt(10000000).toString()), points: orderedCoordinates
            ),
            overshoot);
        _waypointMarkers.clear();
        for (var i = 0; i < waypoints.length; i++) {
          _waypointMarkers.add(
              Marker(
                  markerId: MarkerId('Waypoint Marker ' + i.toString()),
                  position: waypoints[i],
                icon: BitmapDescriptor.defaultMarker,
                alpha: 0.5,
              )
          );
        }
      });
    } else {
      setState(() {
        _polygons.clear();
        _waypointMarkers.clear();
      });
    }
  }

  int _isOnEdge(LatLng tapCoordinates) {
    final List<LatLng> coordinates  = List.from(_markers.map((m) => m.position));
    const tolerance = 0.01; // adjust this value as per your requirement
    for (int i = 0; i < coordinates.length; i++) {
      final currentCoordinate = coordinates[i];
      final nextCoordinate = coordinates[(i + 1) % coordinates.length];
      if (tapCoordinates.latitude >
              min(
                      currentCoordinate.latitude, nextCoordinate.latitude) -
                  tolerance &&
          tapCoordinates.latitude <
              max(currentCoordinate.latitude, nextCoordinate.latitude) +
                  tolerance &&
          tapCoordinates.longitude >
              min(currentCoordinate.longitude, nextCoordinate.longitude) -
                  tolerance &&
          tapCoordinates.longitude <
              max(currentCoordinate.longitude, nextCoordinate.longitude) +
                  tolerance) {
        final slope = (nextCoordinate.latitude - currentCoordinate.latitude) /
            (nextCoordinate.longitude - currentCoordinate.longitude);
        final yIntercept =
            currentCoordinate.latitude - slope * currentCoordinate.longitude;
        final distance = (slope * tapCoordinates.longitude +
                    yIntercept -
                    tapCoordinates.latitude)
                .abs() /
            sqrt(1 + slope * slope);
        if (distance < tolerance) {
          return i;
        }
      }
    }
    return -1;
  }

  Polar _toPolar(LatLng point, LatLng origin) {
    final dx = point.longitude - origin.longitude;
    final dy = point.latitude - origin.latitude;
    final r = sqrt(dx * dx + dy * dy);
    final theta = atan2(dy, dx);
    return Polar(r, theta);
  }

  LatLng _fromPolar(Polar polar, LatLng origin) {
    final x = polar.r * cos(polar.theta) + origin.longitude;
    final y = polar.r * sin(polar.theta) + origin.latitude;
    return LatLng(y, x);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_selectedEdge != -1) {
              // prompt user to delete the edge
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("Delete Edge"),
                  content: Text("Are you sure you want to delete this edge?"),
                  actions: <Widget>[
                    TextButton(
                      child: Text("Cancel"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: Text("Delete"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            }
          },
          child: Icon(Icons.delete),
        ),
        appBar: AppBar(
          title: Text('Google Maps'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.my_location),
              onPressed: () {
                mapController.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(_currentPosition.latitude,
                          _currentPosition.longitude),
                      zoom: 15.0,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: LocationSearch(_searchLocation));
              },
            ),

            // IconButton(
            //   icon: Icon(Icons.edit),
            //   onPressed: _selectedEdge == -1
            //       ? null
            //       : () => _editEdge(LatLng(0,
            //           0)), // replace LatLng(0, 0) with the new coordinate chosen by the user
            // ),
            // IconButton(
            //   icon: Icon(Icons.delete),
            //   onPressed: _deleteEdge,
            // ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(currentLocation?.latitude ?? 0,
                    currentLocation?.longitude ?? 0),
                zoom: 15.0,
              ),
              markers: _markers.union({_currentLocation}.union(_waypointMarkers)),
              // polylines: _polylines,
              polygons: _polygons,
              onLongPress: _onMapLongPress,
              onTap: (LatLng coordinates) {
                setState(() {
                  _selectedEdge = _isOnEdge(coordinates);
                });
              },
            ),
            Positioned(
              bottom: 450,
              right: 15,
              child: Container(
                alignment: Alignment.centerRight,
                child: Column(
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: () {
                        //start button logic
                      },
                      icon: Icon(Icons.play_arrow),
                      label: Text("Start"),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        //stop button logic
                      },
                      icon: Icon(Icons.stop),
                      label: Text("Stop"),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        //upload button logic
                      },
                      icon: Icon(Icons.cloud_upload),
                      label: Text("Upload"),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 450,
              left: 15,
              child: Container(
                  alignment: Alignment.centerRight,
                  child: Column(
                    children: <Widget>[
                      ElevatedButton.icon(
                        label: Text("Go Home"),
                        icon: Icon(Icons.home),
                        onPressed: () {
                          // code to handle "Go Home" button press
                        },
                      ),
                      ElevatedButton.icon(
                        label: Text("Take off"),
                        icon: Icon(Icons.airplanemode_active),
                        onPressed: () {
                          // code to handle "Take off" button press
                        },
                      ),
                      ElevatedButton.icon(
                        label: Text("Terrain"),
                        icon: Icon(Icons.terrain),
                        onPressed: () {
                          // code to handle "Terrain" button press
                        },
                      ),
                      ElevatedButton.icon(
                        label: Text("Bar"),
                        icon: Icon(Icons.terrain),
                        onPressed: () {
                          // code to handle "Bar" button press
                        },
                      ),
                      ElevatedButton.icon(
                        label: Text("Setting"),
                        icon: Icon(Icons.settings),
                        onPressed: () {
                          // code to handle "Setting" button press
                        },
                      ),
                    ],
                  )),
            ),

            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search for a location",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 15, top: 15),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        showSearch(
                            context: context,
                            delegate: LocationSearch(_searchLocation));
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class LocationSearch extends SearchDelegate<String> {
  final Function _searchLocation;

  LocationSearch(this._searchLocation);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    _searchLocation();
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
