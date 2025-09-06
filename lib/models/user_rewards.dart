import 'video_reward.dart';

class UserRewards {
  final int totalBzpPoints;
  final int totalMindDust;
  final List<VideoReward> earnedRewards;
  final Set<String> completedVideos;

  const UserRewards({
    this.totalBzpPoints = 0,
    this.totalMindDust = 0,
    this.earnedRewards = const [],
    this.completedVideos = const {},
  });

  UserRewards copyWith({
    int? totalBzpPoints,
    int? totalMindDust,
    List<VideoReward>? earnedRewards,
    Set<String>? completedVideos,
  }) {
    return UserRewards(
      totalBzpPoints: totalBzpPoints ?? this.totalBzpPoints,
      totalMindDust: totalMindDust ?? this.totalMindDust,
      earnedRewards: earnedRewards ?? this.earnedRewards,
      completedVideos: completedVideos ?? this.completedVideos,
    );
  }

  UserRewards addReward(VideoReward reward, String videoId) {
    final newRewards = List<VideoReward>.from(earnedRewards)..add(reward);
    final newCompletedVideos = Set<String>.from(completedVideos)..add(videoId);
    
    return UserRewards(
      totalBzpPoints: totalBzpPoints + reward.bzpPoints,
      totalMindDust: totalMindDust + reward.mindDust,
      earnedRewards: newRewards,
      completedVideos: newCompletedVideos,
    );
  }

  bool hasCompletedVideo(String videoId) {
    return completedVideos.contains(videoId);
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBzpPoints': totalBzpPoints,
      'totalMindDust': totalMindDust,
      'earnedRewards': earnedRewards.map((r) => r.toJson()).toList(),
      'completedVideos': completedVideos.toList(),
    };
  }

  factory UserRewards.fromJson(Map<String, dynamic> json) {
    return UserRewards(
      totalBzpPoints: json['totalBzpPoints'] as int? ?? 0,
      totalMindDust: json['totalMindDust'] as int? ?? 0,
      earnedRewards: (json['earnedRewards'] as List<dynamic>?)
          ?.map((r) => VideoReward.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      completedVideos: (json['completedVideos'] as List<dynamic>?)
          ?.map((v) => v as String)
          .toSet() ?? {},
    );
  }
}
