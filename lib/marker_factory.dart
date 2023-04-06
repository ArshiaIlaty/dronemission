import 'package:google_maps_flutter/google_maps_flutter.dart';

enum MarkerType { vertex, path, user }

class MarkerFactory {
  static int _vertexMarkerCount = 0;
  static int _pathMarkerCount = 0;

  static Marker createMarker(LatLng position, MarkerType type, {Function(LatLng, String)? onDragEnd, Function(LatLng, String)? onDeletePress}) {
    switch (type) {
      case MarkerType.vertex:
        assert (onDragEnd != null);
        assert (onDeletePress != null);
        final id = 'Vertex ${_vertexMarkerCount++}';
        return Marker(
          markerId: MarkerId(id),
          position: position,
          icon: BitmapDescriptor.defaultMarker,
          draggable: true,
          // Update the polygon if the marker is dragged
          onDragEnd: (LatLng latLng) => onDragEnd!(latLng, id),
          infoWindow: InfoWindow(
            title: "Marker $_vertexMarkerCount",
            snippet: "Tap to delete",
            // Delete the marker if the info window is tapped
            onTap: () => onDeletePress!(position, id),
          ),
          visible: true,
        );

      case MarkerType.path:
        return Marker(
            markerId: MarkerId('Waypoint ${_pathMarkerCount++}'),
            position: position,
            icon: BitmapDescriptor.defaultMarker,
            visible: false,
          );

      case MarkerType.user:
        return Marker(
          markerId: MarkerId("Current Location"),
          position: LatLng(0, 0),
          infoWindow: InfoWindow(title: "Current Location"),
          visible: true,
        );
    }
  }
}