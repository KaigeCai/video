import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video/urls.dart';

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({super.key});

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late Player player;
  late VideoController videoController;
  int currentIndex = 0;
  ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    player = Player();
    videoController = VideoController(player);
    player.open(Media(playUrls[currentIndex]));

    Future.delayed(Duration.zero, () {
      _monitorPlayback();
    });
    super.initState();
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

  void _playPreviousVideo() {
    setState(() {
      currentIndex = (currentIndex - 1 + playUrls.length) % playUrls.length;
      player.open(Media(playUrls[currentIndex]));
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

  void _playNextVideo() {
    setState(() {
      currentIndex = (currentIndex + 1) % playUrls.length;
      player.open(Media(playUrls[currentIndex]));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Video(controller: videoController),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _playPreviousVideo,
                icon: Icon(Icons.skip_previous_rounded),
              ),
              IconButton(
                onPressed: _togglePlayPause,
                icon: ValueListenableBuilder<bool>(
                  valueListenable: isPlayingNotifier,
                  builder: (BuildContext context, bool isPlaying, Widget? child) {
                    return Icon(isPlaying ? Icons.pause : Icons.play_arrow);
                  },
                ),
              ),
              IconButton(
                onPressed: _playNextVideo,
                icon: Icon(Icons.skip_next_rounded),
              ),
            ],
          )
        ],
      ),
    );
  }
}
