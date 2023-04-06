import 'dart:typed_data';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class ImageTileProvider extends TileProvider {
  Future<Tile> getTile(int x, int y, int? zoom) async {
    return await Tile(0, 0, [0] as Uint8List);
  }
}