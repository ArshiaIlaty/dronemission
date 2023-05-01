import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class GenerateThumbnail {
  static Future<File?> getThumbnail() async {
    // final thumbnail = await ImagePicker().getImage(source: ImageSource.gallery);
    final filename = await VideoThumbnail.thumbnailFile(
      video:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      // getTemporaryDirectory() is a method from path_provider package, so we have to add it to pubspec.yaml
      thumbnailPath: (await getTemporaryDirectory()).path,
      //defualt is PNG, but if you want to show high-quality thumbnails, you can set the format to WEBP
      imageFormat: ImageFormat.PNG,
      maxHeight: 64,
      maxWidth: 64,
      quality: 100,
    );
    if (filename == null) return null;
    File file = File(filename);
    return file;
  }
}
