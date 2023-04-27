import 'dart:math';
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
      Future<ByteData?> imageData =
          getImageData(); // Assuming getImageData() returns a Future<ByteData?>
      ByteData? data =
          await imageData; // Wait for the Future to complete and get the resulting ByteData
      if (data != null) {
        Uint8List bytes = data.buffer
            .asUint8List(); // Access the buffer property on the ByteData
        // Use the bytes to display the image or do other operations
        completer.complete(bytes);
      }
    }));
    return completer.future;
  }

  Future<Uint8List> loadImages(LatLngBounds bounds, int zoom) async {
    final url =
        '$imageUrl/$zoom/${bounds.southWest.latitude},${bounds.southWest.longitude},${bounds.northEast.latitude},${bounds.northEast.longitude}.png';
    final imageBytes = await NetworkAssetBundle(Uri.parse(url)).load('');
    final image = await decodeImageFromList(imageBytes.buffer.asUint8List());

    final tileSize = 256;
    final xTiles = (bounds.northEast.longitude - bounds.southWest.longitude) *
        pow(2, zoom) /
        360.0;
    final yTiles =
        log(tan((pi / 4) + ((bounds.northEast.latitude / 2) * pi / 180))) /
            pi /
            2 *
            pow(2, zoom);
    final x = ((bounds.southWest.longitude + 180) / 360 * pow(2, zoom)).floor();
    final y = ((1 -
                log(tan(bounds.northEast.latitude * pi / 180) +
                        1 / cos(bounds.northEast.latitude * pi / 180)) /
                    pi) /
            2 *
            pow(2, zoom))
        .floor();

    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    final cropX =
        ((bounds.southWest.longitude + 180) / 360 * imageWidth).round();
    final cropY = ((1 -
                log(tan(bounds.northEast.latitude * pi / 180) +
                        1 / cos(bounds.northEast.latitude * pi / 180)) /
                    pi) /
            2 *
            imageHeight)
        .round();
    final cropWidth = (xTiles * tileSize).ceil();
    final cropHeight = (yTiles * tileSize).ceil();

    final buffer = ByteData(cropWidth * cropHeight * 4);
    for (var y = 0; y < cropHeight; y++) {
      for (var x = 0; x < cropWidth; x++) {
        final imageX = (cropX + x).clamp(0, imageWidth.toInt() - 1);
        final imageY = (cropY + y).clamp(0, imageHeight.toInt() - 1);
        final pixelColor =
            byteData.getUint32((imageY * imageWidth + imageX) * 4);
        buffer.setUint32((y * cropWidth + x) * 4, pixelColor);
      }
    }
    return buffer.buffer.asUint8List();
  }
}
