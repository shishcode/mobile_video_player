import 'package:flutter/material.dart';
import '../../models/video_data.dart';
import '../../models/video_reward.dart';
import '../../models/user_rewards.dart';
import '../../services/reward_service.dart';
import '../../services/reward_storage_shared_prefs.dart';
import '../../screens/video_reward_screen.dart';

class VideoRewardPlayer extends StatelessWidget {
  final VideoData video;
  final RewardService rewardService;
  final void Function(VideoReward reward, UserRewards updated)? onRewardEarned;

  const VideoRewardPlayer({
    super.key,
    required this.video,
    RewardService? rewardService,
    this.onRewardEarned,
  }) : rewardService = rewardService ?? RewardService(SharedPrefsRewardStorage());

  @override
  Widget build(BuildContext context) {
    return VideoRewardScreen(
      videoData: video,
      rewardService: rewardService,
      onRewardEarned: onRewardEarned,
    );
  }
}
