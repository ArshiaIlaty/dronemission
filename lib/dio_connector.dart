import 'package:dio/dio.dart';

final dio = Dio();

class ServerConnection {
  final String root;

  ServerConnection(this.root);

  Future<Response> Send(Map<String, dynamic> data, String path) {
    return dio.get(
      this.root + path, data: data
    );
  }

  Future<Response> Request(String path) {
    return dio.get(
        this.root + path
    );
  }
}