import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'common/globals.dart';
import 'common/widgets.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player = Player();
  late final VideoController controller = VideoController(
    player,
    configuration: configuration.value,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ValueListenableBuilder<VideoControllerConfiguration>(
          valueListenable: configuration,
          builder: (context, value, _) => TextButton(
            onPressed: () {
              configuration.value = VideoControllerConfiguration(
                enableHardwareAcceleration: !value.enableHardwareAcceleration,
              );
            },
            child: Text(value.enableHardwareAcceleration ? '硬件加速' : '软件加速'),
          ),
        ),
        actions: [
          IconButton(
            tooltip: '打开文件夹',
            onPressed: () {},
            icon: const Icon(Icons.view_list_rounded),
          ),
          IconButton(
            tooltip: '打开文件夹',
            onPressed: () {},
            icon: const Icon(Icons.folder_copy),
          ),
          IconButton(
            tooltip: '打开文件',
            onPressed: () => showFilePicker(context, player),
            icon: const Icon(Icons.file_open),
          ),
          IconButton(
            tooltip: '打开链接',
            onPressed: () => showURIPicker(context, player),
            icon: const Icon(Icons.link),
          ),
        ],
      ),
      body: Video(controller: controller),
    );
  }
}
