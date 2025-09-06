import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'reward_storage.dart';

class SharedPrefsRewardStorage implements RewardStorage {
  static const String _rewardsKey = 'user_rewards';

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rewardsKey);
  }

  @override
  Future<Map<String, dynamic>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final rewardsJson = prefs.getString(_rewardsKey);
    if (rewardsJson == null) return null;
    try {
      return jsonDecode(rewardsJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rewardsKey, jsonEncode(json));
  }
}
