import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CustomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? fallbackUrl;
  final Duration maxWatchedTime;
  final bool allowSeeking; // when false: clamp forward seek to maxWatched
  final bool disableAllSeeking; // when true: slider disabled entirely (after completion)
  final VoidCallback? onVideoCompleted;
  final VoidCallback? onPauseDetected;
  final Function(Duration) onProgressUpdate;

  const CustomVideoPlayer({
    super.key,
    required this.videoUrl,
    this.fallbackUrl,
    required this.maxWatchedTime,
    required this.allowSeeking,
    this.disableAllSeeking = false,
    this.onVideoCompleted,
    this.onPauseDetected,
    required this.onProgressUpdate,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isFullscreen = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _pauseTimer;
  Duration _currentPosition = Duration.zero;
  double _volume = 1.0;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.setLooping(false);
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.addListener(_onVideoTick);
      await WakelockPlus.enable();
    } catch (e) {
      print('Error initializing video player: $e');
      // Try fallback if provided
      if (widget.fallbackUrl != null && widget.fallbackUrl!.isNotEmpty) {
        try {
          _controller.removeListener(_onVideoTick);
          await _controller.dispose();
          _controller = VideoPlayerController.networkUrl(Uri.parse(widget.fallbackUrl!));
          await _controller.initialize();
          setState(() {
            _isInitialized = true;
          });
          _controller.addListener(_onVideoTick);
          await WakelockPlus.enable();
          return;
        } catch (e2) {
          print('Fallback video also failed: $e2');
        }
      }
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onVideoTick() {
    if (!_controller.value.isInitialized) return;
    
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    final isPlaying = _controller.value.isPlaying;
    // Capture previous state to detect transitions correctly
    final bool wasPlaying = _isPlaying;
    if (mounted && wasPlaying != isPlaying) {
      setState(() => _isPlaying = isPlaying);
      if (!isPlaying && wasPlaying) {
        _onPause();
      } else if (isPlaying && !wasPlaying) {
        _onResume();
      }
    }
    
    _currentPosition = position;
    widget.onProgressUpdate(position);
    
    // Check if video completed
    if (!duration.isNegative && position >= duration - const Duration(milliseconds: 500)) {
      widget.onVideoCompleted?.call();
    }
  }

  void _onPause() {
    _pauseTimer?.cancel();
    _pauseTimer = Timer(const Duration(milliseconds: 1500), () {
      widget.onPauseDetected?.call();
    });
    _hideControlsTimer?.cancel();
    if (mounted) {
      setState(() => _showControls = true);
    }
  }

  void _onResume() {
    _pauseTimer?.cancel();
    _scheduleHideControls();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _pauseTimer?.cancel();
    _controller.removeListener(_onVideoTick);
    _controller.dispose();
    WakelockPlus.disable();
    _restoreSystemUI();
    super.dispose();
  }

  void _togglePlay() {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _scheduleHideControls();
  }

  void _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    setState(() => _isFullscreen = true);
    _scheduleHideControls();
  }

  Future<void> _restoreSystemUI() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // iPhones often don't allow upside-down; request portraitUp only to avoid iOS errors.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _exitFullscreen() async {
    await _restoreSystemUI();
    if (mounted) setState(() => _isFullscreen = false);
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    if (_controller.value.isPlaying) {
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        if (_controller.value.isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  Future<void> _seekTo(Duration position) async {
    if (widget.disableAllSeeking) {
      return;
    }
    if (!widget.allowSeeking && position > widget.maxWatchedTime) {
      // Don't allow seeking beyond watched time
      position = widget.maxWatchedTime;
    }
    await _controller.seekTo(position);
    if (_controller.value.isPlaying) {
      _scheduleHideControls();
    }
  }

  void _setVolume(double v) {
    final nv = v.clamp(0.0, 1.0);
    _controller.setVolume(nv);
    setState(() {
      _volume = nv;
      _isMuted = nv == 0.0;
    });
  }

  void _toggleMute() {
    if (_isMuted) {
      // Restore to a sane default
      _setVolume(_volume == 0.0 ? 0.6 : _volume);
    } else {
      _setVolume(0.0);
    }
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }
    return '${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final duration = _controller.value.duration;
    final current = _controller.value.position;
    final totalMs = duration.inMilliseconds;
    final currentMs = current.inMilliseconds.clamp(0, totalMs);
    final maxWatchedMs = widget.maxWatchedTime.inMilliseconds.clamp(0, totalMs);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen
          ? null
          : AppBar(
              title: const Text('Video Ödül Sistemi'),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
      body: SafeArea(
        top: !_isFullscreen,
        bottom: !_isFullscreen,
        left: !_isFullscreen,
        right: !_isFullscreen,
        child: Center(
          child: _isInitialized
              ? _controller.value.hasError
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'Video yüklenirken hata oluştu',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'İnternet bağlantınızı kontrol edin',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return AspectRatio(
                          aspectRatio: _controller.value.aspectRatio == 0
                              ? 16 / 9
                              : _controller.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _togglePlay();
                                  setState(() => _showControls = true);
                                  _scheduleHideControls();
                                },
                                child: VideoPlayer(_controller),
                              ),
                              if (_showControls)
                                _VideoControlsOverlay(
                                  isPlaying: _isPlaying,
                                  current: current,
                                  duration: duration,
                                  maxWatched: widget.maxWatchedTime,
                                  allowSeeking: widget.allowSeeking,
                                  seekingEnabled: !widget.disableAllSeeking,
                                  onPlayPause: _togglePlay,
                                  onSeekTo: _seekTo,
                                  onEnterFullscreen:
                                      _isFullscreen ? null : _enterFullscreen,
                                  onExitFullscreen:
                                      _isFullscreen ? _exitFullscreen : null,
                                  formatDuration: _formatDuration,
                                  volume: _volume,
                                  isMuted: _isMuted,
                                  onVolumeChanged: _setVolume,
                                  onToggleMute: _toggleMute,
                                ),
                            ],
                          ),
                        );
                      },
                    )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}

class _VideoControlsOverlay extends StatefulWidget {
  final bool isPlaying;
  final Duration current;
  final Duration duration;
  final Duration maxWatched;
  final bool allowSeeking;
  final bool seekingEnabled;
  final VoidCallback onPlayPause;
  final Future<void> Function(Duration position) onSeekTo;
  final VoidCallback? onEnterFullscreen;
  final VoidCallback? onExitFullscreen;
  final String Function(Duration) formatDuration;
  final double volume;
  final bool isMuted;
  final void Function(double) onVolumeChanged;
  final VoidCallback onToggleMute;

  const _VideoControlsOverlay({
    required this.isPlaying,
    required this.current,
    required this.duration,
    required this.maxWatched,
    required this.allowSeeking,
    required this.seekingEnabled,
    required this.onPlayPause,
    required this.onSeekTo,
    this.onEnterFullscreen,
    this.onExitFullscreen,
    required this.formatDuration,
    required this.volume,
    required this.isMuted,
    required this.onVolumeChanged,
    required this.onToggleMute,
  });

  @override
  State<_VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _VideoControlsOverlayState extends State<_VideoControlsOverlay> {
  double? _dragValueMs;

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.duration.inMilliseconds;
    final currentMs = widget.current.inMilliseconds.clamp(0, totalMs);
    final maxWatchedMs = widget.maxWatched.inMilliseconds.clamp(0, totalMs);
    final canExitFs = widget.onExitFullscreen != null;
    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;
    final bool isTablet = shortest >= 600;
    final double iconMain = isTablet ? 96 : 80;
    final double pad = isTablet ? 24 : 16;
    final double sliderHeight = isTablet ? 8 : 6;
    final double volumeWidth = isTablet ? 140 : 100;
    final TextStyle timeStyle = TextStyle(
      color: Colors.white,
      fontSize: isTablet ? 16 : 14,
      fontFamily: 'monospace',
    );

    return Stack(
      children: [
        // Top gradient veil
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Top bar
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canExitFs)
                          IconButton(
                            onPressed: widget.onExitFullscreen,
                            icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                          ),
                        if (!canExitFs && widget.onEnterFullscreen != null)
                          IconButton(
                            onPressed: widget.onEnterFullscreen,
                            icon: const Icon(Icons.fullscreen, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Center play button
        Center(
          child: IconButton(
            onPressed: widget.onPlayPause,
            iconSize: iconMain,
            color: Colors.white.withOpacity(0.95),
            icon: Icon(widget.isPlaying ? Icons.pause_circle : Icons.play_circle),
          ),
        ),

        // Bottom control glass bar
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, pad),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tap anywhere on the overlay background (excluding controls) to toggle
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: widget.onPlayPause,
                          child: const SizedBox(height: 0),
                        ),
                        // Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: sliderHeight,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                            inactiveTrackColor: Colors.white24,
                            activeTrackColor: Colors.white,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            min: 0,
                            max: totalMs.toDouble(),
                            value: (_dragValueMs ?? currentMs.toDouble())
                                .clamp(0, totalMs.toDouble()),
                            onChanged: widget.seekingEnabled
                                ? (value) {
                                    setState(() {
                                      final allowedMax = widget.allowSeeking
                                          ? totalMs.toDouble()
                                          : maxWatchedMs.toDouble();
                                      _dragValueMs = value.clamp(0.0, allowedMax);
                                    });
                                  }
                                : null,
                            onChangeEnd: widget.seekingEnabled
                                ? (value) {
                                    final requested = Duration(milliseconds: value.round());
                                    _dragValueMs = null;
                                    widget.onSeekTo(requested);
                                  }
                                : null,
                          ),
                        ),

                        // Watched progress underline
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 2,
                            width: totalMs == 0
                                ? 0
                                : (MediaQuery.of(context).size.width - pad * 2 - 32) *
                                    (maxWatchedMs / totalMs),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Time and volume row
                        LayoutBuilder(
                          builder: (ctx, constraints) {
                            final double maxW = constraints.maxWidth;
                            final bool tight = maxW < (isTablet ? 420 : 320);
                            final bool ultraTight = maxW < (isTablet ? 360 : 280);

                            final Widget timeStart = Text(
                              widget.formatDuration(Duration(milliseconds: currentMs)),
                              style: timeStyle,
                            );
                            final Widget timeEnd = Text(
                              widget.formatDuration(Duration(milliseconds: totalMs)),
                              style: timeStyle,
                            );

                            final Widget volumeControls = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: widget.onToggleMute,
                                  icon: Icon(
                                    widget.isMuted || widget.volume == 0.0
                                        ? Icons.volume_off
                                        : (widget.volume < 0.5
                                            ? Icons.volume_down
                                            : Icons.volume_up),
                                    color: Colors.white,
                                    size: isTablet ? 24 : 20,
                                  ),
                                ),
                                if (!ultraTight)
                                  SizedBox(
                                    width: tight ? (isTablet ? 110 : 80) : volumeWidth,
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: isTablet ? 4 : 3,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                        inactiveTrackColor: Colors.white24,
                                        activeTrackColor: Colors.white,
                                        thumbColor: Colors.white,
                                      ),
                                      child: Slider(
                                        min: 0,
                                        max: 1,
                                        value: widget.volume.clamp(0.0, 1.0),
                                        onChanged: (v) => widget.onVolumeChanged(v),
                                      ),
                                    ),
                                  ),
                              ],
                            );

                            return Row(
                              children: [
                                timeStart,
                                const Spacer(),
                                if (!tight) volumeControls,
                                if (!tight) const SizedBox(width: 8),
                                timeEnd,
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
