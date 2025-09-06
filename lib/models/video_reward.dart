class VideoReward {
  final int bzpPoints;
  final int mindDust;
  final String reason;
  final DateTime earnedAt;

  const VideoReward({
    required this.bzpPoints,
    required this.mindDust,
    required this.reason,
    required this.earnedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'bzpPoints': bzpPoints,
      'mindDust': mindDust,
      'reason': reason,
      'earnedAt': earnedAt.toIso8601String(),
    };
  }

  factory VideoReward.fromJson(Map<String, dynamic> json) {
    return VideoReward(
      bzpPoints: json['bzpPoints'] as int,
      mindDust: json['mindDust'] as int,
      reason: json['reason'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );
  }

  VideoReward copyWith({
    int? bzpPoints,
    int? mindDust,
    String? reason,
    DateTime? earnedAt,
  }) {
    return VideoReward(
      bzpPoints: bzpPoints ?? this.bzpPoints,
      mindDust: mindDust ?? this.mindDust,
      reason: reason ?? this.reason,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }
}
