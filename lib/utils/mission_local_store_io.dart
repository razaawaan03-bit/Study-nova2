import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Stores missions as one JSON file in the app's documents directory.
///
/// Everything is best effort: a missing directory, a locked file or a missing
/// `path_provider` implementation must never stop Mission Mode from running.
/// The file simply becomes a cache that Supabase can re-populate.
class MissionLocalStore {
  MissionLocalStore();

  static const String _fileName = 'study_nova_missions.json';

  File? _cachedFile;

  Future<File?> _resolveFile() async {
    if (_cachedFile != null) return _cachedFile;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}$_fileName');
      _cachedFile = file;
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> readAll() async {
    try {
      final file = await _resolveFile();
      if (file == null || !await file.exists()) return const [];

      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return const [];

      final decoded = jsonDecode(contents);
      if (decoded is! List) {
        await _quarantine(file, 'not a JSON list');
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on FormatException catch (e) {
      // A damaged file must not silently read back as "no missions at all":
      // keep it aside so it can be inspected, and start clean.
      final file = await _resolveFile();
      if (file != null) await _quarantine(file, 'invalid JSON (${e.message})');
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeAll(List<Map<String, dynamic>> missions) async {
    try {
      final file = await _resolveFile();
      if (file == null) return;

      // Write to a temporary file and rename it over the real one. A crash or
      // a kill in the middle of a plain `writeAsString` would leave a
      // truncated file, and every mission would be lost on the next launch;
      // a rename is atomic on every platform Study Nova ships to.
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(jsonEncode(missions), flush: true);
      await temporary.rename(file.path);
    } catch (_) {
      // Local persistence is a convenience, never a requirement.
    }
  }

  Future<void> clear() async {
    try {
      final file = await _resolveFile();
      if (file == null || !await file.exists()) return;
      await file.delete();
    } catch (_) {
      // Ignore.
    }
  }

  /// Moves an unreadable file to `<name>.corrupt` so the damaged data is kept
  /// for inspection instead of being silently overwritten.
  Future<void> _quarantine(File file, String reason) async {
    try {
      debugPrint(
        'MissionLocalStore: ${file.path} could not be read ($reason). '
        'Keeping it as ${file.path}.corrupt and starting with no missions.',
      );
      await file.rename('${file.path}.corrupt');
    } catch (_) {
      // If even the rename fails there is nothing more to try.
    }
  }
}
