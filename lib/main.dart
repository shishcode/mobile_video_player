import 'package:flutter/material.dart';
import 'models/video_data.dart';
import 'widgets/video/video_reward_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Ödül Sistemi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const VideoRewardPlayer(
        video: VideoData.bigBuckBunny,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

