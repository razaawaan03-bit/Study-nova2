// Local persistence for Study Nova Missions on platforms that have a file
// system. On web the stub implementation is used instead, so missions simply
// stay in memory there (or come from Supabase when it is reachable).
//
// Mirrors the conditional-import pattern already used by
// `lib/utils/material_file_reader.dart` so this stays web-safe.
export 'mission_local_store_stub.dart'
    if (dart.library.io) 'mission_local_store_io.dart';
