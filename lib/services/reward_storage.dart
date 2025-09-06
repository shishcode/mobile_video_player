abstract class RewardStorage {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> json);
  Future<void> clear();
}
