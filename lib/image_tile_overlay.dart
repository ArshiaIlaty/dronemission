import 'dart:typed_data';
import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class ImageTileProvider extends TileProvider {
  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    return Tile(0, 0, [0] as Uint8List);
  }
}