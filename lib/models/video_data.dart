class VideoData {
  final String id;
  final String title;
  final String url;
  final String? fallbackUrl;
  final String thumbnailUrl;
  final int rewardBzp;
  final int rewardMindDust;
  final Duration duration;
  final bool isTestVideo;

  const VideoData({
    required this.id,
    required this.title,
    required this.url,
    this.fallbackUrl,
    required this.thumbnailUrl,
    required this.rewardBzp,
    required this.rewardMindDust,
    required this.duration,
    this.isTestVideo = false,
  });

  static const VideoData bigBuckBunny = VideoData(
    id: 'big_buck_bunny',
    title: 'Big Buck Bunny',
    url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    fallbackUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    thumbnailUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
    rewardBzp: 100,
    rewardMindDust: 50,
    duration: Duration(minutes: 10, seconds: 34),
  );

  static const VideoData testVideo = VideoData(
    id: 'test_video',
    title: 'Test Video (Kısa)',
    url: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
    fallbackUrl: 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
    thumbnailUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
    rewardBzp: 100,
    rewardMindDust: 50,
    duration: Duration(seconds: 30),
    isTestVideo: true,
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'fallbackUrl': fallbackUrl,
      'thumbnailUrl': thumbnailUrl,
      'rewardBzp': rewardBzp,
      'rewardMindDust': rewardMindDust,
      'duration': duration.inMilliseconds,
      'isTestVideo': isTestVideo,
    };
  }

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      fallbackUrl: json['fallbackUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String,
      rewardBzp: json['rewardBzp'] as int,
      rewardMindDust: json['rewardMindDust'] as int,
      duration: Duration(milliseconds: json['duration'] as int),
      isTestVideo: json['isTestVideo'] as bool? ?? false,
    );
  }
}
