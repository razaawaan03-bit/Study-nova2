/// Web / no-file-system fallback: missions are kept in memory by
/// `MissionService` and nothing is written to disk.
class MissionLocalStore {
  const MissionLocalStore();

  Future<List<Map<String, dynamic>>> readAll() async => const [];

  Future<void> writeAll(List<Map<String, dynamic>> missions) async {}

  Future<void> clear() async {}
}
