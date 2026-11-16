// Reads the bytes of a local file on platforms where file paths are usable.
//
// Mirrors the conditional-import pattern used by `mission_local_store.dart`
// so this stays web-safe.
export 'material_file_reader_stub.dart'
    if (dart.library.io) 'material_file_reader_io.dart'
    if (dart.library.html) 'material_file_reader_web.dart';
