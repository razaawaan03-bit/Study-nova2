import 'dart:typed_data';

/// Web fallback: the browser picker always provides the bytes itself, and a
/// `blob:` URL cannot be read through the file system, so nothing is read
/// here and the caller falls back to the bytes captured while picking.
Future<Uint8List?> readBytesFromPath(String path) async => null;
