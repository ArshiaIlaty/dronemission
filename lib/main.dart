// import 'dart:html';
import 'dart:math';
import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' show Geolocator, Placemark;
import 'package:flutter_geocoder/geocoder.dart';
// import 'package:triangulation/triangulation.dart';
// import 'package:delaunay/delaunay.dart';
// import 'package:delaunay_triangulation/delaunay_triangulation.dart';
// import 'package:earcut/earcut.dart';

void main() => runApp(MyApp());

class Polar {
  final double r;
  final double theta;
  Polar(this.r, this.theta);
}

class MyApp extends StatefulWidget {
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
  int _selectedEdge = -1;
  late double _newLatitude;
  late double _newLongitude;
  Set<Polygon> _polygons = {};
  // List<Polygon> _polygons = [];
  final List<LatLng> _coordinates = [];
  final Geolocator geolocator = Geolocator();
  final TextEditingController _searchController = TextEditingController();

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        this.currentLocation = currentLocation;
        _markers.add(
          Marker(
            markerId: MarkerId("Current Location"),
            position:
                LatLng(currentLocation.latitude!, currentLocation.longitude!),
            infoWindow: InfoWindow(title: "Current Location"),
          ),
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
    final markerId = MarkerId(_coordinates.length.toString());
    _coordinates.add(latLng);
    _markers.add(Marker(
      markerId: markerId,
      position: latLng,
      icon: BitmapDescriptor.defaultMarker,
      draggable: true,
      onDragEnd: (latLng) {
        final markerList = _markers.toList();
        final index = markerList.indexWhere((marker) => marker.markerId == markerId);
        _coordinates[index] = latLng;
        _updatePolygon();
      },
      infoWindow: InfoWindow(
        title: "Marker ${_coordinates.length}",
        snippet: "Tap to delete",
        onTap: () => _onDeletePress(latLng, markerId),
      ),
    ));
    _updatePolygon();
  }

  void _onDeletePress(LatLng latLng, MarkerId markerId) {
    final markerList = _markers.toList();
    final index1 = markerList.indexWhere((marker) => marker.markerId == markerId);
    final index = _coordinates.indexWhere((element) => (element.longitude == latLng.longitude) && (element.latitude == latLng.latitude));
    setState(() {
      print("index: ${index}");
      print("cordinate length ${_coordinates.length.toString()}");
      _markers.remove(index1);
      _coordinates.removeAt(index);
      _polygons = Set.of(_polygons.toList()..removeAt(index));
    });
    _updatePolygon();
  }

  void _updatePolygon() {
    _polygons.clear();
    print("cordinate length ${_coordinates.length.toString()}");
    if (_coordinates.length >= 3) {
      final origin = _coordinates.reduce((value, element) => LatLng(
          (value.latitude + element.latitude) / 2,
          (value.longitude + element.longitude) / 2));
      final polarCoordinates =
      _coordinates.map((c) => _toPolar(c, origin)).toList();
      polarCoordinates.sort((a, b) =>
      a.theta == b.theta ? a.r.compareTo(b.r) : a.theta.compareTo(b.theta));
      final orderedCoordinates =
      polarCoordinates.map((p) => _fromPolar(p, origin)).toList();
      setState(() {
        _polygons.clear();
        _polygons.add(Polygon(
          polygonId: PolygonId(_coordinates.length.toString()),
          points: orderedCoordinates,
          fillColor: Colors.green.withOpacity(0.5),
          strokeWidth: 5,
          strokeColor: Colors.green,
        ));
      });
    }
    // else {
    //   setState(() {
    //     _polygons.clear();
    //   });
    // }
  }

  int _isOnEdge(LatLng tapCoordinates) {
    final tolerance = 0.01; // adjust this value as per your requirement
    for (int i = 0; i < _coordinates.length; i++) {
      final currentCoordinate = _coordinates[i];
      final nextCoordinate = _coordinates[(i + 1) % _coordinates.length];
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
                        setState(() {
                          _coordinates.removeAt(_selectedEdge);
                        });
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
            // IconButton(
            //   icon: Icon(Icons.search),
            //   onPressed: () {
            //     showSearch(context: context, delegate: LocationSearch(_searchLocation));
            //   },
            // ),

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
              markers: _markers,
              polygons: _polygons,
              onLongPress: _onMapLongPress,
              onTap: (LatLng coordinates) {
                setState(() {
                  _selectedEdge = _isOnEdge(coordinates);
                });
              },
            ),
            // Positioned(
            //   top: 0,
            //   bottom: 0,
            //   left: 0,
            //   right: 0,
            //   child: Align(
            //     alignment: Alignment.center,
            //     child: Column(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: <Widget>[
            //         for (final polygon in _polygons)
            //           InkWell(
            //             onLongPress: () {
            //               showDialog(
            //                 context: context,
            //                 builder: (_) {
            //                   return AlertDialog(
            //                     title: Text('Edit or Delete'),
            //                     content: Column(
            //                       mainAxisSize: MainAxisSize.min,
            //                       children: <Widget>[
            //                         ElevatedButton(
            //                           child: Text('Edit'),
            //                           onPressed: () {
            //                             // code for editing the polygon here
            //                           },
            //                         ),
            //                         ElevatedButton(
            //                           child: Text('Delete'),
            //                           onPressed: () {
            //                             _polygons.remove(polygon);
            //                             setState(() {});
            //                           },
            //                         ),
            //                       ],
            //                     ),
            //                   );
            //                 },
            //               );
            //             },
            //             // child: polygon,
            //           ),
            //       ],
            //     ),
            //   ),
            // ),
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

class CustomMarker extends StatelessWidget {
  final LatLng coordinates;
  final int index;
  final Function onDeletePress;
  final Function onEditPress;

  CustomMarker(
      {required this.coordinates,
      required this.index,
      required this.onDeletePress,
      required this.onEditPress});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Text("Marker $index"),
          TextButton(
            child: Text("Delete"),
            onPressed: () => onDeletePress(index),
          ),
          TextButton(
            child: Text("Edit"),
            onPressed: () => onEditPress(index),
          ),
        ],
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
