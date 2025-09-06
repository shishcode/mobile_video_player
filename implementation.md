# Video Reward System - Integration Guide

This package provides a ready-to-integrate video reward experience with:
- Anti-cheat progress (no seeking beyond watched boundary until completion)
- Encouragement dialog on pause/idle
- Rewards upon completion (BZP and AkılTozu)
- Responsive, glassmorphic UI; fullscreen landscape mode

## 1) Key Files
- `lib/widgets/video/video_reward_player.dart`: Facade widget to drop into any screen
- `lib/screens/video_reward_screen.dart`: Reward logic container
- `lib/widgets/video/custom_video_player.dart`: Custom controls and anti-cheat seeking
- `lib/widgets/dialogs/*`: Reward and encouragement dialogs
- `lib/widgets/badges/reward_badges.dart`: Persistent badge overlay
- `lib/services/reward_service.dart`: Reward orchestration service
- `lib/services/reward_storage.dart`: Storage abstraction
- `lib/services/reward_storage_shared_prefs.dart`: Default SharedPreferences storage
- `lib/models/*`: `VideoData`, `VideoReward`, `UserRewards`

## 2) Dependencies
Ensure `pubspec.yaml` contains:
- `video_player`
- `wakelock_plus`
- `shared_preferences`

Run:
```bash
flutter pub get
```

## 3) Basic Usage (Facade)
```dart
import 'package:your_app/widgets/video/video_reward_player.dart';
import 'package:your_app/models/video_data.dart';

class RewardsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const VideoRewardPlayer(
      video: VideoData.bigBuckBunny, // or your own VideoData
    );
  }
}
```

## 4) Inject Your Own Storage/Service (Optional)
Implement `RewardStorage` to persist in your system (e.g., secure storage, backend):
```dart
class MyRewardStorage implements RewardStorage {
  @override
  Future<Map<String, dynamic>?> read() async { /* ... */ }
  @override
  Future<void> write(Map<String, dynamic> json) async { /* ... */ }
  @override
  Future<void> clear() async { /* ... */ }
}
```
Wire it via the facade or screen:
```dart
final service = RewardService(MyRewardStorage());
VideoRewardPlayer(
  video: myVideo,
  rewardService: service,
  onRewardEarned: (reward, updated) {
    // Sync with your backend or analytics
  },
);
```

## 5) Provide Custom Videos
Create your own `VideoData`:
```dart
const myVideo = VideoData(
  id: 'lesson_42',
  title: 'Lesson 42',
  url: 'https://cdn.example.com/videos/lesson42.mp4',
  fallbackUrl: 'https://cdn.example.com/videos/lesson42_backup.mp4',
  thumbnailUrl: 'https://cdn.example.com/thumbs/lesson42.jpg',
  rewardBzp: 100,
  rewardMindDust: 50,
  duration: Duration(minutes: 12, seconds: 5),
);
```

## 6) Anti-Cheat Mechanics
- Users cannot seek beyond `maxWatchedTime` until completion
- Dragging the slider is clamped; release also clamps
- After first completion, seeking is fully disabled (configurable in `VideoRewardScreen` via `disableAllSeeking`)

## 7) Encouragement & Rewards
- Encouragement dialog appears if paused for ~1.5s before completion
- On completion, reward dialog shows BZP and AkılTozu
- State persists via `RewardStorage` (default: SharedPreferences)

## 8) Fullscreen Behavior
- Fullscreen button enters immersive landscape and hides header in landscape
- Tapping video toggles play/pause and reveals controls
- Controls auto-hide after 3s while playing

## 9) iOS & Android Setup
- iOS: CocoaPods installed; `pod install` in `ios` directory
- Android: Internet permission already added. Ensure NDK version if building release

## 10) Hooks You Can Use
- `VideoRewardPlayer.onRewardEarned`: listen and push to backend
- Replace `RewardService`/`RewardStorage` for custom persistence

## 11) Theming
- The overlay uses Material 3; adjust colors via app theme
- Glassmorphic controls use blur and transparency; safe for light/dark

## 12) QA Checklist
- Seek forward blocked until completion
- Pause for >1.5s triggers encouragement dialog
- Completion shows reward dialog and disables seeking
- Fullscreen rotates to landscape and covers full screen
- Tapping video toggles play/pause in portrait and landscape

That’s it. Use the facade for fast adoption, or compose the lower-level pieces for advanced control.
