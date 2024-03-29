import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:flutter_geocoder/geocoder.dart';
import 'package:custom_marker/marker_icon.dart';
import 'package:dronemission/utils.dart';
import 'package:dronemission/pathing.dart';
import 'package:dronemission/otp_screen.dart';
import 'package:dronemission/marker_factory.dart';
import 'package:dronemission/slidebar_widget.dart';
import 'package:dronemission/image_tile_overlay.dart';
import 'clock_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:draggable_widget/draggable_widget.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
// import 'package:timezone/timezone.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:dartdoc/dartdoc.dart';

import 'package:device_preview/device_preview.dart';

// import 'package:hive/hive.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';

// import 'package:cloud_firestore_web/cloud_firestore_web.dart';

// initializing hive

// void main() async {
//   await Hive.initFlutter();
//   runApp(const MyApp());
// }

// this part of code should be in some parts of the app
// Use Hive to store and retrieve data by opening boxes and adding or getting values from them.

// await Hive.openBox('myBox');
// var box = Hive.box('myBox');
// box.put('key', 'value');
// var value = box.get('key');

// Main function to run the MyApp widget
void main() => runApp(const MyApp());

// Polar class to represent polar coordinates
class Polar {
  final double r;
  final double theta;
  Polar(this.r, this.theta);
}

// MyApp widget which extends the StatefulWidget class
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

// State class for the MyApp widget
class _MyAppState extends State<MyApp> {
  // Controller for the Google Map widget
  late GoogleMapController mapController;

  // Location class instance
  Location location = Location();

  // Current location data
  LocationData? currentLocation;

  // String for search query
  late String _searchString;

  // Current position in lat, long coordinates
  late Position _currentPosition;

  // Set of markers for the map
  Set<Marker> _markers = {};

  // Marker for the current location
  late Marker _currentLocation;

  // Index of the selected edge
  int _selectedEdge = -1;

  // Set of polyggon shapes on the map
  final Set<Polygon> _polygons = {};

  // Set of markers for waypoints
  Set<Marker> _waypointMarkers = {};

  // Geolocator instance for location services
  final Geolocator geolocator = Geolocator();

  // TextEditingController for the search bar
  final TextEditingController _searchController = TextEditingController();

  // List of polylines on the map
  List<Polyline> _polylines = [];

  // Random number generator instance
  static final random = Random();

  final ImageTileProvider tileProvider = ImageTileProvider(
    imageUrl: 'http://134.197.62.248:8000/images/mines',
  );

  // Callback function when the map is created
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // final dio = Dio();
  //
  // void getHttp() async {
  //   Response response;
  //   response = await dio.get('https://mineexchange.com/drone');
  //   print(response);
  //
  //   //Downloading a file
  //   response = await dio.download(
  //     'https://pub.dev/',
  //     (await getTemporaryDirectory()).path + 'pub.html',);
  //   //Performing a POST request in order to send the result file:
  //   response = await dio.post('/test', data: {'id': 12, 'name': 'dio'});
  //
  //   //Listening the uploading progress:
  //   response = await dio.post(
  //     'https://www.dtworkroom.com/doris/1/2.0.0/test',
  //     data: {'aa': 'bb' * 22},
  //     onSendProgress: (int sent, int total) {
  //       print('$sent $total');
  //     },
  //   );
  // }

  // Override of the initState method to initialize the widget
  @override
  void initState() {
    super.initState();
    // Initialize the current location marker
    _currentLocation =
        MarkerFactory.createMarker(LatLng(0, 0), MarkerType.user);

    // Listen for changes in the location and update the marker
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        this.currentLocation = currentLocation;
        _currentLocation = _currentLocation.copyWith(
            positionParam:
                LatLng(currentLocation.latitude!, currentLocation.longitude!));
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
    // Get the user's query from the text controller
    final query = _searchController.text;

    // Check if the query is not empty
    if (query.isNotEmpty) {
      // Find addresses from the query using the geocoder library
      final results = await Geocoder.local.findAddressesFromQuery(query);

      // If the results list is not empty
      if (results.isNotEmpty) {
        // Get the first result
        final first = results.first;

        // Animate the camera to the location of the first result
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                  first.coordinates.latitude!, first.coordinates.longitude!),
              zoom: 15.0,
            ),
          ),
        );
      }
    }
  }

  getUserLocation() async {
    // Get the user's current location
    var location = Location();
    var permission = await location.requestPermission();
    var userLocation = await location.getLocation();

    // Set the current position state to the user's current location
    setState(() {
      _currentPosition = userLocation as Position;
    });
  }

  void _onMapLongPress(LatLng latLng) {
    // Set state to add a marker on the map when the map is long pressed
    setState(() {
      // Check if a marker with the same markerId already exists
      final marker = MarkerFactory.createMarker(latLng, MarkerType.vertex,
          onDragEnd: (LatLng newPosition, String id) {
        _markers = Set.from(_markers.map((m) => m.markerId.value == id
            ? m.copyWith(positionParam: newPosition)
            : m));
        _updatePolygon();
      }, onDeletePress: _onDeletePress);
      _markers.add(marker);
      _updatePolygon();
    });
  }

  void _onDeletePress(LatLng latLng, String markerId) {
    // Set state to remove a marker when its info window is tapped
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == markerId);
    });
    _updatePolygon();
  }

  void _updatePolygon() {
    // Clear the existing polygon
    _polygons.clear();

    // If there are at least three markers, update the polygon
    if (_markers.length >= 3) {
      // Get a set of the marker positions
      final test = Set.from(_markers.map((m) => m.position));

      // Calculate the origin of the polygon
      final origin = test.reduce((value, element) => LatLng(
          (value.latitude + element.latitude) / 2,
          (value.longitude + element.longitude) / 2));

      // Convert the marker positions to polar coordinates
      final polarCoordinates = test.map((c) => _toPolar(c, origin)).toList();

      // Sort the polar coordinates based on the angle and distance
      polarCoordinates.sort((a, b) =>
          a.theta == b.theta ? a.r.compareTo(b.r) : a.theta.compareTo(b.theta));

      // Convert the sorted polar coordinates back to LatLng coordinates
      final orderedCoordinates =
          polarCoordinates.map((p) => _fromPolar(p, origin)).toList();

      // Update the polygon with the ordered LatLng coordinates
      setState(() {
        _polygons.clear();
        _polygons.add(Polygon(
          polygonId: PolygonId(test.length.toString()),
          points: orderedCoordinates,
          fillColor: Colors.green.withOpacity(0.5),
          strokeWidth: 3,
          strokeColor: Colors.green,
        ));

        // Add waypoint markers along the polygon
        const double overshoot = 10.0;
        final waypoints = getWaypointsAlongPolygon(
            Polygon(
                polygonId: PolygonId(random.nextInt(10000000).toString()),
                points: orderedCoordinates),
            overshoot);
        _waypointMarkers.clear();
        for (var i = 0; i < waypoints.length; i++) {
          _waypointMarkers
              .add(MarkerFactory.createMarker(waypoints[i], MarkerType.path));
        }

        final path = findPath(_polygons.first, 20);
        final polyline = Polyline(
          polylineId: const PolylineId('1'),
          color: Colors.red,
          width: 1,
          jointType: JointType.round,
          points: path,
        );
        if (_polylines.isEmpty) {
          _polylines.add(polyline);
        } else {
          _polylines[0] = polyline;
        }
      });
    } else {
      // If there are less than three markers, clear the polygon and waypoint markers
      setState(() {
        _polygons.clear();
        _waypointMarkers.clear();
      });
    }
  }

// Check if a given LatLng coordinate is on the edge of the polygon
  int _isOnEdge(LatLng tapCoordinates) {
    final List<LatLng> coordinates = List.from(_markers.map((m) => m.position));
    const tolerance = 0.01; // adjust this value as per your requirement
    for (int i = 0; i < coordinates.length; i++) {
      final currentCoordinate = coordinates[i];
      final nextCoordinate = coordinates[(i + 1) % coordinates.length];

      // Check if the tap coordinates are within the bounds of the current and next coordinate
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

        // Check if the distance between the tap coordinates and the edge is within the tolerance
        if (distance < tolerance) {
          return i;
        }
      }
    }
    return -1;
  }

  //The _toPolar function converts a point in cartesian coordinate to polar coordinate.
  Polar _toPolar(LatLng point, LatLng origin) {
    final dx = point.longitude - origin.longitude;
    final dy = point.latitude - origin.latitude;
    final r = sqrt(dx * dx + dy * dy);
    final theta = atan2(dy, dx);
    return Polar(r, theta);
  }

  //The _fromPolar function converts a point in polar coordinate to cartesian coordinate.
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
                  title: const Text("Delete Edge"),
                  content:
                      const Text("Are you sure you want to delete this edge?"),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: const Text("Delete"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            }
          },
          child: const Icon(Icons.delete),
        ),
        appBar: AppBar(
          //using animate widget to animate the title
          title: Animate(effects: [
            FadeEffect(duration: 10000.ms, delay: 500.ms, begin: 0.5),
            ScaleEffect(
              duration: 10000.ms,
            ),
          ], child: Text('Google Maps')),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.my_location),
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
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                    context: context,
                    delegate: LocationSearch(_searchLocation));
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
              markers:
                  _markers.union({_currentLocation}.union(_waypointMarkers)),
              polygons: _polygons,
              polylines: _polylines.toSet(),
              onLongPress: _onMapLongPress,
              onTap: (LatLng coordinates) {
                setState(() {
                  _selectedEdge = _isOnEdge(coordinates);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('snack'),
                    duration: const Duration(seconds: 1),
                    action: SnackBarAction(
                        label: 'ACTION',
                        onPressed: () {
                          _selectedEdge = _isOnEdge(coordinates);
                        }),
                  ));
                });
              },
              tileOverlays: {
                TileOverlay(
                  tileProvider: tileProvider,
                  tileOverlayId: const TileOverlayId('1'),
                  zIndex: 100,
                ),
              },
            ),
            Column(
              children: [
                SizedBox(height: 100, width: 200, child: ClockWidget()),
                SizedBox(height: 100, width: 500, child: SliderExample()),
              ],
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
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Start"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        //stop button logic
                      },
                      icon: const Icon(Icons.stop),
                      label: const Text("Stop"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        //upload button logic
                      },
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text("Upload"),
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
                        label: const Text("Go Home"),
                        icon: const Icon(Icons.home),
                        onPressed: () {
                          // code to handle "Go Home" button press
                        },
                      ),
                      ElevatedButton.icon(
                        label: const Text("Take off"),
                        icon: const Icon(Icons.airplanemode_active),
                        onPressed: () {
                          // code to handle "Take off" button press
                        },
                      ),
                      ElevatedButton.icon(
                        label: const Text("Terrain"),
                        icon: const Icon(Icons.terrain),
                        onPressed: () {
                          // code to handle "Terrain" button press
                        },
                      ),
                      ElevatedButton.icon(
                        label: const Text("Bar"),
                        icon: const Icon(Icons.terrain),
                        onPressed: () {
                          // code to handle "Bar" button press
                        },
                      ),
                      ElevatedButton.icon(
                        label: const Text("Setting"),
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          // code to handle "Setting" button press
                        },
                      ),
                    ],
                  )),
            ),
            Positioned(
              top: 70,
              left: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: const Text("Overlap"),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return SimpleDialog(
                            title: const Text("Overlap"),
                            children: [
                              Slider(
                                value: 50,
                                min: 5,
                                max: 95,
                                divisions: 90,
                                label: '50%',
                                onChanged: (value) {
                                  print(value);
                                },
                              ),
                              Slider(
                                value: 50,
                                min: 5,
                                max: 95,
                                divisions: 90,
                                label: '50%',
                                onChanged: (value) {
                                  print(value);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
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
                    contentPadding: const EdgeInsets.only(left: 15, top: 15),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
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
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
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

class MyScreenWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OptScreen(); // Replace MyScreen with the name of your screen widget
  }
}
