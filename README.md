# Video Reward Mobile

A Flutter implementation of a professional video reward experience featuring:
- Anti-cheat progress bar (forward seek clamped until completion)
- Encouragement modal on pause/idle to keep users engaged
- Completion rewards: BZP and AkılTozu
- Responsive, glassmorphic UI with fullscreen landscape playback

## Quick Start
1. Install dependencies:
```bash
flutter pub get
```
2. Run on a device/emulator:
```bash
flutter run
```
3. Build APK:
```bash
flutter build apk --release
```

## Files of Interest
- `lib/widgets/video/video_reward_player.dart`: Facade widget to drop into any app
- `lib/screens/video_reward_screen.dart`: Reward logic container
- `lib/widgets/video/custom_video_player.dart`: Custom player & controls
- `lib/services/reward_service.dart`: Reward orchestration (injectable)
- `lib/services/reward_storage.dart`: Storage abstraction
- `lib/services/reward_storage_shared_prefs.dart`: Default SharedPreferences storage
- `lib/models/*`: `VideoData`, `VideoReward`, `UserRewards`

## Implementation Guide (For Mustafa)
Please follow the step-by-step instructions in `implementation.md` to integrate this into the main app. It includes:
- How to plug in your own storage
- How to listen to reward events
- How to customize videos and UI

> See: `implementation.md`

## Notes
- iOS requires CocoaPods; run `pod install` inside `ios/` after `flutter pub get`.
- Internet permission is already configured for Android.
- Fullscreen toggles immersive landscape and hides non-video UI in landscape.
