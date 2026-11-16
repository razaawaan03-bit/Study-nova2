import 'dart:typed_data';

/// Stub used when neither `dart:io` nor `dart:html` is available.
Future<Uint8List?> readBytesFromPath(String path) async => null;
