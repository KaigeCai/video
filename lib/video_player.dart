import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video/urls.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late Player player;
  late VideoController videoController;

  int currentIndex = 0;

  ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    player = Player();
    videoController = VideoController(player);
    player.open(Media(playUrl[currentIndex]));

    Future.delayed(Duration.zero, () {
      _monitorPlayback();
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _monitorPlayback() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (player.platform!.state.completed) {
        _playNextVideo();
      }
    }
  }

  void _playNextVideo() {
    setState(() {
      currentIndex = (currentIndex + 1) % playUrl.length;
      player.open(Media(playUrl[currentIndex]));
    });
  }

  void _playPreviousVideo() {
    setState(() {
      currentIndex = (currentIndex - 1 + playUrl.length) % playUrl.length;
      player.open(Media(playUrl[currentIndex]));
    });
  }

  void _togglePlayPause() {
    if (player.state.playing) {
      player.pause();
      isPlayingNotifier.value = false;
    } else {
      player.play();
      isPlayingNotifier.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Video(
              controller: videoController,
              fit: BoxFit.contain,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous),
                onPressed: _playPreviousVideo,
              ),
              IconButton(
                icon: ValueListenableBuilder<bool>(
                  valueListenable: isPlayingNotifier,
                  builder: (context, isPlaying, child) {
                    return Icon(isPlaying ? Icons.pause : Icons.play_arrow);
                  },
                ),
                onPressed: _togglePlayPause,
              ),
              IconButton(
                icon: Icon(Icons.skip_next),
                onPressed: _playNextVideo,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
