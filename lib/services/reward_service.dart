import '../models/user_rewards.dart';
import '../models/video_reward.dart';
import 'reward_storage.dart';

class RewardService {
  final RewardStorage storage;

  RewardService(this.storage);

  Future<UserRewards> getUserRewards() async {
    final map = await storage.read();
    if (map == null) return const UserRewards();
    try {
      return UserRewards.fromJson(map);
    } catch (_) {
      return const UserRewards();
    }
  }

  Future<void> saveUserRewards(UserRewards rewards) async {
    await storage.write(rewards.toJson());
  }

  Future<UserRewards> addReward(VideoReward reward, String videoId) async {
    final current = await getUserRewards();
    final updated = current.addReward(reward, videoId);
    await saveUserRewards(updated);
    return updated;
  }

  Future<bool> hasCompletedVideo(String videoId) async {
    final rewards = await getUserRewards();
    return rewards.hasCompletedVideo(videoId);
  }

  Future<void> resetRewards() async {
    await storage.clear();
  }
}
