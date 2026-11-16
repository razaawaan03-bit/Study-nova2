import 'dart:io';
import 'dart:typed_data';

/// Reads a local file into memory, returning null when it cannot be read.
///
/// Used for picked files on mobile/desktop, where the picker returns a path
/// instead of the bytes (for example macOS, where `withData` is unsupported).
Future<Uint8List?> readBytesFromPath(String path) async {
  try {
    if (path.trim().isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}
