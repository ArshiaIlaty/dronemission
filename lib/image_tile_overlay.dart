import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:buffer/buffer.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ImageTileProvider extends TileProvider {
  final String imageUrl;
  final int tileSize;

  ImageTileProvider({required this.imageUrl, this.tileSize = 256});

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    final url = '$imageUrl/$zoom/$x/$y.png';
    final imageBytes = await loadImage(url);
    // Image.asset('assets/images/lake.jpg'),
    return Tile(0, 0, [0] as Uint8List);
    // return Tile(tileSize, tileSize, imageBytes);

    // final response = await http.get(Uri.parse('$imageUrl/$zoom/$x/$y.png'));
    //   if (response.statusCode == 200) {
    //     return Tile(width: tileSize, height: tileSize, bytes: response.bodyBytes);
    //   }
    //   return Tile(width: tileSize, height: tileSize, bytes: Uint8List(0));
    //   }
  }

    Future<ByteData?> getImageData() async {
    // Implementation logic for getting the image data
  }

  Future<Uint8List> loadImage(String url) async {
  final completer = Completer<Uint8List>();
  final image = NetworkImage(url);
  final stream = image.resolve(ImageConfiguration.empty);
  stream.addListener(ImageStreamListener((image, _) async {
    final byteData = image.image.toByteData(format: ui.ImageByteFormat.png);
    Future<ByteData?> imageData = getImageData(); // Assuming getImageData() returns a Future<ByteData?>
    ByteData? data = await imageData; // Wait for the Future to complete and get the resulting ByteData
    if (data != null) {
      Uint8List bytes = data.buffer.asUint8List(); // Access the buffer property on the ByteData
      // Use the bytes to display the image or do other operations
      completer.complete(bytes);
    }
  }));
  return completer.future;
  }
}