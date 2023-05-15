import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef WebpImageBytes = Uint8List;



class ImageTileProvider extends TileProvider {
  final String imageUrl;
  final int tileSize;

  final WebpImageBytes emptyImage = base64Decode('UklGRhoAAABXRUJQVlA4TA0AAAAvAAAAEAcQERGIiP4HAA');

  ImageTileProvider({required this.imageUrl, this.tileSize = 256});

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    final url = '$imageUrl?x=$x&y=$y&zoom=$zoom';
    final imageBytes = await loadImage(url);
    return Tile(tileSize, tileSize, imageBytes);
  }

  Future<Uint8List> loadImage(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'image/webp',
        'Accept': 'image/webp',
        'Username': 'TestUser',
        'Organization': 'TestOrg',
        'Mine': 'TestMine',
      },
    ).catchError((error) {
      return http.Response('', 404);
    });
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    return emptyImage;
  }
}