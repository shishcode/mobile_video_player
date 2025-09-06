import 'dart:async';
import 'package:flutter/material.dart';
import '../models/video_data.dart';
import '../models/video_reward.dart';
import '../models/user_rewards.dart';
import '../services/reward_service.dart';
import '../services/reward_storage_shared_prefs.dart';
import '../widgets/video/custom_video_player.dart';
import '../widgets/dialogs/reward_dialog.dart';
import '../widgets/dialogs/encouragement_dialog.dart';
import '../widgets/badges/reward_badges.dart';

class VideoRewardScreen extends StatefulWidget {
  final VideoData videoData;
  final RewardService? rewardService;
  final void Function(VideoReward reward, UserRewards updated)? onRewardEarned;

  const VideoRewardScreen({
    super.key,
    required this.videoData,
    this.rewardService,
    this.onRewardEarned,
  });

  @override
  State<VideoRewardScreen> createState() => _VideoRewardScreenState();
}

class _VideoRewardScreenState extends State<VideoRewardScreen> {
  late final RewardService _rewardService =
      widget.rewardService ?? RewardService(SharedPrefsRewardStorage());
  UserRewards _userRewards = const UserRewards();
  Duration _maxWatchedTime = Duration.zero;
  bool _allowSeeking = false; // disallow forward seeking until completion
  bool _hasEarnedReward = false;
  bool _showEncouragementDialog = false;
  bool _showRewardDialog = false;
  bool _isLoading = false;
  bool _disableAllSeeking = false; // disable seeking after completion per spec

  @override
  void initState() {
    super.initState();
    _loadUserRewards();
  }

  Future<void> _loadUserRewards() async {
    final rewards = await _rewardService.getUserRewards();
    final hasCompleted = await _rewardService.hasCompletedVideo(widget.videoData.id);
    
    setState(() {
      _userRewards = rewards;
      _hasEarnedReward = hasCompleted;
      // Anti-cheat: disallow forward seeking unless already completed in the past
      _allowSeeking = false;
      _disableAllSeeking = hasCompleted;
    });
  }

  void _onProgressUpdate(Duration position) {
    if (position > _maxWatchedTime) {
      setState(() {
        _maxWatchedTime = position;
      });
    }
  }

  void _onVideoCompleted() async {
    if (_hasEarnedReward) return;
    
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    final reward = VideoReward(
      bzpPoints: widget.videoData.rewardBzp,
      mindDust: widget.videoData.rewardMindDust,
      reason: 'Video tamamlandı: ${widget.videoData.title}',
      earnedAt: DateTime.now(),
    );

    final updatedRewards = await _rewardService.addReward(reward, widget.videoData.id);
    widget.onRewardEarned?.call(reward, updatedRewards);
    
    setState(() {
      _userRewards = updatedRewards;
      _hasEarnedReward = true;
      _allowSeeking = true; // user can play freely but seeking can be fully disabled if desired
      _disableAllSeeking = true; // per spec: disable seeking after first completion
      _isLoading = false;
      _showRewardDialog = true;
    });
  }

  void _onPauseDetected() {
    if (!_hasEarnedReward && !_showEncouragementDialog) {
      setState(() {
        _showEncouragementDialog = true;
      });
    }
  }

  void _onContinueWatching() {
    setState(() {
      _showEncouragementDialog = false;
    });
  }

  void _onDismissEncouragement() {
    setState(() {
      _showEncouragementDialog = false;
    });
  }

  void _onCloseRewardDialog() {
    setState(() {
      _showRewardDialog = false;
    });
  }

  void _switchToTestVideo() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => VideoRewardScreen(
          videoData: VideoData.testVideo,
          rewardService: _rewardService,
          onRewardEarned: widget.onRewardEarned,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isLandscape = size.width > size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Header
              if (!isLandscape)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Video Ödül Sistemi - Flutter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Videoları izleyerek BZP Puanları ve AkılTozu kazanın!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Test Video Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _switchToTestVideo,
                        icon: const Icon(Icons.science, color: Colors.white),
                        label: const Text(
                          '🧪 Test Video (Kısa)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Video Player
              Expanded(
                child: CustomVideoPlayer(
                  videoUrl: widget.videoData.url,
                  fallbackUrl: widget.videoData.fallbackUrl,
                  maxWatchedTime: _maxWatchedTime,
                  allowSeeking: _allowSeeking,
                  disableAllSeeking: _disableAllSeeking,
                  onVideoCompleted: _onVideoCompleted,
                  onPauseDetected: _onPauseDetected,
                  onProgressUpdate: _onProgressUpdate,
                ),
              ),
            ],
          ),
          
          // Reward Badges
          RewardBadges(userRewards: _userRewards),
          
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.green,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Ödüller hesaplanıyor...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Dialogs
          if (_showEncouragementDialog)
            EncouragementDialog(
              onContinue: _onContinueWatching,
              onDismiss: _onDismissEncouragement,
              bzpReward: widget.videoData.rewardBzp,
              mindDustReward: widget.videoData.rewardMindDust,
            ),
          
          if (_showRewardDialog)
            RewardDialog(
              reward: VideoReward(
                bzpPoints: widget.videoData.rewardBzp,
                mindDust: widget.videoData.rewardMindDust,
                reason: 'Video tamamlandı: ${widget.videoData.title}',
                earnedAt: DateTime.now(),
              ),
              onClose: _onCloseRewardDialog,
            ),
        ],
      ),
    );
  }
}
